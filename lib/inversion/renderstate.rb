#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'loggability'
require 'inversion' unless defined?( Inversion )


# An object that provides an encapsulation of the template's state while it is rendering.
class Inversion::RenderState
	extend Loggability
	include Inversion::DataUtilities


	# Loggability API -- set up logging through the Inversion module's logger
	log_to :inversion

	# An encapsulation of the scope in which the bodies of tags evaluate. It's
	# used to provide a controlled, isolated namespace which remains the same from
	# tag to tag.
	class Scope < BasicObject

		### Create a new RenderState::Scope with its initial tag locals set to
		### +locals+.
		def initialize( locals={}, fragments={} )
			@locals = locals
			@fragments = fragments
		end


		### Return the tag local with the specified +name+.
		def []( name )
			return @locals[ name.to_sym ]
		end


		### Set the tag local with the specified +name+ to +value+.
		def []=( name, value )
			@locals[ name.to_sym ] = value
		end


		### Return a copy of the receiving Scope merged with the given +values+,
		### which can be either another Scope or a Hash.
		def +( values )
			return Scope.new( self.__locals__.merge(values), self.__fragments__ )
		end


		### Return the Hash of tag locals the belongs to this scope.
		def __locals__
			return @locals
		end
		alias_method :to_hash, :__locals__


		### Returns the Hash of rendered fragments that belong to this scope.
		def __fragments__
			return @fragments
		end


		#########
		protected
		#########

		### The main trickery behind this class -- intercept tag locals as method calls
		### and map them into values from the Scope's locals.
		def method_missing( sym, *args, &block )
			return super unless sym =~ /^\w+$/
			return @locals[ sym ].nil? ? @fragments[ sym ] : @locals[ sym ]
		end

	end # class Scope


	### Create a new RenderState. If the template is being rendered inside another one, the
	### containing template's RenderState will be passed as the +containerstate+. The
	### +initial_attributes+ will be deep-copied, and the +options+ will be merged with
	### Inversion::Template::DEFAULT_CONFIG. The +block+ is stored for use by
	### template nodes.
	def initialize( containerstate=nil, initial_attributes={}, options={}, &block )

		# Shift hash arguments if created without a parent state
		if containerstate.is_a?( Hash )
			options = initial_attributes
			initial_attributes = containerstate
			containerstate = nil
		end

		# self.log.debug "Creating a render state with attributes: %p" %
		#	[ initial_attributes ]

		locals = deep_copy( initial_attributes )
		@scopes             = [ Scope.new(locals) ]

		@start_time         = Time.now
		@containerstate     = containerstate
		@options            = Inversion::Template::DEFAULT_CONFIG.merge( options )
		@block              = block
		@default_errhandler = self.method( :default_error_handler )
		@errhandler         = @default_errhandler
		@rendering_enabled  = true

		# The rendered output Array, the stack of render destinations and
		# tag states
		@output             = []
		@destinations       = [ @output ]
		@tag_data          = [ {} ]

		# Hash of subscribed Nodes and published data, keyed by the subscription key
		# as a Symbol
		@subscriptions      = Hash.new {|hsh, k| hsh[k] = [] } # Auto-vivify to an Array
		@published_nodes    = Hash.new {|hsh, k| hsh[k] = [] }
		@fragments          = Hash.new {|hsh, k| hsh[k] = [] }

	end


	######
	public
	######

	# The Inversion::RenderState of the containing template, if any
	attr_reader :containerstate

	# The config options passed in from the template
	attr_reader :options

	# The block passed to the template's #render method, if there was one
	attr_reader :block

	# Subscribe placeholders for publish/subscribe
	attr_reader :subscriptions

	# Published nodes, keyed by subscription
	attr_reader :published_nodes

	# Fragment nodes, keyed by fragment name
	attr_reader :fragments

	# The stack of rendered output destinations, most-recent last.
	attr_reader :destinations

	# The callable object that handles exceptions raised when a node is appended
	attr_reader :errhandler

	# The default error handler
	attr_reader :default_errhandler

	# The Time the object was created
	attr_reader :start_time


	### Return the hash of attributes that are currently in effect in the
	### rendering state.
	def scope
		return @scopes.last
	end


	### Return a Hash that tags can use to track state for the current render.
	def tag_data
		return @tag_data.last
	end


	### Evaluate the specified +code+ in the context of itself and
	### return the result.
	def eval( code )
		# self.log.debug "Evaling: %p" [ code ]
		return self.scope.instance_eval( code )
	end


	### Backward-compatibility -- return the tag locals of the current scope as a Hash.
	def attributes
		return self.scope.__locals__
	end


	### Override the state's attributes with the given +overrides+, call the +block+, then
	### restore the attributes to their original values.
	def with_attributes( overrides )
		raise LocalJumpError, "no block given" unless block_given?
		# self.log.debug "Overriding template attributes with: %p" % [ overrides ]

		begin
			newscope = self.scope + overrides
			@scopes.push( newscope )
			yield( self )
		ensure
			@scopes.pop
		end
	end


	### Add an overlay to the current tag state Hash, yield to the provided block, then
	### revert the tag state back to what it was prior to running the block.
	def with_tag_data( newhash={} )
		raise LocalJumpError, "no block given" unless block_given?
		# self.log.debug "Overriding tag state with: %p" % [ newhash ]

		begin
			@tag_data.push( @tag_data.last.merge(newhash) )
			yield( self )
		ensure
			@tag_data.pop
		end
	end


	### Override the state's render destination, call the block, then restore the original
	### destination when the block returns.
	def with_destination( new_destination )
		raise LocalJumpError, "no block given" unless block_given?
		# self.log.debug "Overriding render destination with: %p" % [ new_destination ]

		begin
			@destinations.push( new_destination )
			yield
		ensure
			# self.log.debug "  removing overridden render destination: %p" % [ @destinations.last ]
			@destinations.pop
		end

		return new_destination
	end


	### Set the state's error handler to +handler+ for the duration of the block, restoring
	### the previous handler after the block exits. +Handler+ must respond to #call, and will
	### be called with two arguments: the node that raised the exception, and the exception object
	### itself.
	def with_error_handler( handler )
		original_handler = self.errhandler
		raise ArgumentError, "%p doesn't respond_to #call" unless handler.respond_to?( :call )
		@errhandler = handler

		yield

	ensure
		@errhandler = original_handler
	end


	### Return the current rendered output destination.
	def destination
		return self.destinations.last
	end


	### Returns a new RenderState containing the attributes and options of the receiver
	### merged with those of the +otherstate+.
	def merge( otherstate )
		merged = self.dup
		merged.merge!( otherstate )
		return merged
	end


	### Merge the attributes and options of the +otherstate+ with those of the receiver,
	### replacing any with the same keys.
	def merge!( otherstate )
		@scopes.push( @scopes.pop + otherstate.scope )
		# self.attributes.merge!( otherstate.attributes )
		self.options.merge!( otherstate.options )
		return self
	end


	### Append operator -- add an node to the final rendered output. If the +node+ renders
	### as an object that itself responds to the #render method, #render will be called and
	### the return value will be appended instead. This will continue until the returned
	### object either doesn't respond to #render or #renders as itself.
	def <<( node )
		# self.log.debug "Appending a %p to %p" % [ node.class, self ]
		original_node = node
		original_node.before_rendering( self )

		if self.rendering_enabled?
			self.destination << self.make_node_comment( node ) if self.options[:debugging_comments]
			previous_node = nil
			enc = self.options[:encoding] || Encoding.default_internal

			begin
				# Allow render to be delegated to subobjects
				while node.respond_to?( :render ) && node != previous_node
					# self.log.debug "    delegated rendering to: %p" % [ node ]
					previous_node = node
					node = node.render( self )
				end

				# self.log.debug "  adding a %p (%p; encoding: %s) to the destination (%p)" %
				#	[ node.class, node, node.respond_to?(:encoding) ? node.encoding : 'n/a', self.destination.class ]
				self.destination << node
				# self.log.debug "    just appended %p to %p" % [ node, self.destination ]
			rescue ::StandardError => err
				# self.log.debug "  handling a %p while rendering: %s" % [ err.class, err.message ]
				self.destination << self.handle_render_error( original_node, err )
			end
		end

		original_node.after_rendering( self )
		return self
	end


	### Turn the rendered node structure into the final rendered String.
	def to_s
		return self.stringify_nodes( @output )
	end


	### Publish the given +nodes+ to all subscribers to the specified +key+.
	def publish( key, *nodes )
		key = key.to_sym
		# self.log.debug "[0x%016x] Publishing %p nodes: %p" % [ self.object_id * 2, key, nodes ]

		self.containerstate.publish( key, *nodes ) if self.containerstate
		self.subscriptions[ key ].each do |subscriber|
			# self.log.debug "  sending %d nodes to subscriber: %p (a %p)" %
			#     [ nodes.length, subscriber, subscriber.class ]
			subscriber.publish( *nodes )
		end
		self.published_nodes[ key ].concat( nodes )
	end
	alias_method :publish_nodes, :publish


	### Subscribe the given +node+ to nodes published with the specified +key+.
	def subscribe( key, node )
		key = key.to_sym
		self.log.debug "Adding subscription to %p nodes for %p" % [ key, node ]
		self.subscriptions[ key ] << node
		# self.log.debug "  now have subscriptions for: %p" % [ self.subscriptions.keys ]
		if self.published_nodes.key?( key )
			self.log.debug "    re-publishing %d %p nodes to late subscriber" %
				[ self.published_nodes[key].length, key ]
			node.publish( *self.published_nodes[key] )
		end
	end


	### Add one or more rendered +nodes+ to the state as a reusable fragment associated
	### with the specified +name+.
	def add_fragment( name, *nodes )
		self.log.debug "Adding a %s fragment with %d nodes." % [ name, nodes.size ]
		nodes.flatten!
		self.fragments[ name.to_sym ] = nodes
		self.scope.__fragments__[ name.to_sym ] = nodes
	end


	### Return the current fragments Hash rendered as Strings.
	def rendered_fragments
		self.log.debug "Rendering fragments: %p." % [ self.fragments.keys ]
		return self.fragments.each_with_object( {} ) do |(key, nodes), accum|
			accum[ key ] = self.stringify_nodes( nodes )
		end
	end


	### Handle an +exception+ that was raised while appending a node by calling the
	### #errhandler.
	def handle_render_error( node, exception )
		self.log.error "%s while rendering %p: %s" %
			[ exception.class.name, node.as_comment_body, exception.message ]

		handler = self.errhandler
		raise ScriptError, "error handler %p isn't #call-able!" % [ handler ] unless
			handler.respond_to?( :call )

		self.log.debug "Handling %p with handler: %p" % [ exception.class, handler ]
		return handler.call( self, node, exception )

	rescue ::StandardError => err
		# Handle exceptions from overridden error handlers (re-raised or errors in
		# the handler itself) via the default handler.
		if handler && handler != self.default_errhandler
			self.log.error "%p (re)raised from custom error handler %p" % [ err.class, handler ]
			self.default_errhandler.call( self, node, exception )
		else
			raise( err )
		end
	end


	### Default exception handler: Handle an +exception+ while rendering +node+ according to the
	### behavior specified by the `on_render_error` option. Returns the string which should be
	### appended to the output, if any.
	def default_error_handler( state, node, exception )
		case self.options[:on_render_error].to_s
		when 'ignore'
			self.log.debug "  not rendering anything for the error"
			return ''

		when 'comment'
			self.log.debug "  rendering error as a comment"
			msg = "%s: %s" % [ exception.class.name, exception.message ]
			if self.options[:debugging_comments]
				exception.backtrace.each {|line| msg << "\n" << line }
			end
			return self.make_comment( msg )

		when 'propagate'
			self.log.debug "  propagating error while rendering"
			raise( exception )

		else
			raise Inversion::OptionsError,
				"unknown exception-handling mode: %p" % [ self.options[:on_render_error] ]
		end
	end


	### Return +true+ if rendered nodes are being saved for output.
	def rendering_enabled?
		return @rendering_enabled ? true : false
	end


	### Enable rendering, causing nodes to be appended to the rendered output.
	def enable_rendering
		@rendering_enabled = true
	end


	### Disable rendering, causing rendered nodes to be discarded instead of appended.
	def disable_rendering
		@rendering_enabled = false
	end


	### Toggle rendering, enabling it if it was disabled, and vice-versa.
	def toggle_rendering
		@rendering_enabled = !@rendering_enabled
	end


	### Return the number of floting-point seconds that have passed since the
	### object was created. Used to time renders.
	def time_elapsed
		return Time.now - self.start_time
	end


	### Return a human-readable representation of the object.
	def inspect
		return "#<%p:0x%08x containerstate: %s, scope locals: %s, destination: %p>" % [
			self.class,
			self.object_id / 2,
			self.containerstate ? "0x%08x" % [ self.containerstate.object_id ] : "nil",
			self.scope.__locals__.keys.sort.join(', '),
			self.destination.class,
		]
	end


	#########
	protected
	#########

	### Return the +node+ as a comment if debugging comments are enabled.
	def make_node_comment( node )
		comment_body = node.as_comment_body or return ''
		return self.make_comment( comment_body )
	end


	### Return the specified +content+ inside of the configured comment characters.
	def make_comment( content )
		return [
			self.options[:comment_start],
			content,
			self.options[:comment_end],
		].join
	end


	### Return the given +nodes+ as a String in the configured encoding.
	def stringify_nodes( nodes )
		self.log.debug "Rendering nodes: %p" % [ nodes ]
		strings = nodes.flatten.map( &:to_s )

		if enc = self.options[ :encoding ]
			self.log.debug "Encoding rendered template parts to %s" % [ enc ]
			strings.map! {|str| str.encode(enc, invalid: :replace, undef: :replace) }
		end

		return strings.join
	end


	### Handle attribute methods.
	def method_missing( sym, *args, &block )
		return super unless sym.to_s =~ /^\w+$/
		# self.log.debug "mapping missing method call to tag local: %p" % [ sym ]
		return self.scope[ sym ]
	end


end # class Inversion::RenderState

