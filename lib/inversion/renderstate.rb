#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion' unless defined?( Inversion )


# An object that provides an encapsulation of the template's state while it is rendering.
class Inversion::RenderState
	include Inversion::Loggable

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

		self.log.debug "Creating a render state with attributes: %p" %
			[ initial_attributes ]

		@containerstate     = containerstate
		@options            = Inversion::Template::DEFAULT_CONFIG.merge( options )
		@attributes         = [ deep_copy(initial_attributes) ]
		@block              = block
		@default_errhandler = self.method( :default_error_handler )
		@errhandler         = @default_errhandler
		@rendering_enabled  = true

		# The rendered output Array, the stack of render destinations and
		# tag states
		@output             = []
		@destinations       = [ @output ]
		@tag_state          = [ {} ]

		# Hash of subscribed Nodes, keyed by the subscription key as a Symbol
		@subscriptions      = Hash.new {|hsh, k| hsh[k] = [] } # Auto-vivify

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

	# The stack of rendered output destinations, most-recent last.
	attr_reader :destinations

	# The callable object that handles exceptions raised when a node is appended
	attr_reader :errhandler

	# The default error handler
	attr_reader :default_errhandler


	### Return the hash of attributes that are currently in effect in the
	### rendering state.
	def attributes
		return @attributes.last
	end


	### Return a Hash that tags can use to track state for the current render.
	def tag_state
		return @tag_state.last
	end


	### Evaluate the specified +code+ in the context of itself and
	### return the result.
	def eval( code )
		self.log.debug "Evaling: %p" [ code ]
		return self.instance_eval( code )
	end


	### Override the state's attributes with the given +overrides+, call the +block+, then
	### restore the attributes to their original values.
	def with_attributes( overrides )
		raise LocalJumpError, "no block given" unless block_given?
		self.log.debug "Overriding template attributes with: %p" % [ overrides ]

		begin
			@attributes.push( @attributes.last.merge(overrides) )
			yield( self )
		ensure
			@attributes.pop
		end
	end


	### Add an overlay to the current tag state Hash, yield to the provided block, then
	### revert the tag state back to what it was prior to running the block.
	def with_tag_state( newhash={} )
		raise LocalJumpError, "no block given" unless block_given?
		self.log.debug "Overriding tag state with: %p" % [ newhash ]

		begin
			@tag_state.push( @tag_state.last.merge(newhash) )
			yield( self )
		ensure
			@tag_state.pop
		end
	end


	### Override the state's render destination, call the block, then restore the original
	### destination when the block returns.
	def with_destination( new_destination )
		raise LocalJumpError, "no block given" unless block_given?
		self.log.debug "Overriding render destination with: %p" % [ new_destination ]

		begin
			@destinations.push( new_destination )
			yield
		ensure
			self.log.debug "  removing overridden render destination: %p" % [ @destinations.last ]
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
		self.attributes.merge!( otherstate.attributes )
		self.options.merge!( otherstate.options )
		return self
	end


	### Append operator -- add an node to the final rendered output. If the +node+ renders 
	### as an object that itself responds to the #render method, #render will be called and 
	### the return value will be appended instead. This will continue until the returned
	### object either doesn't respond to #render or #renders as itself.
	def <<( node )
		self.log.debug "Appending a %p to %p" % [ node.class, self ]
		self.destination << self.make_node_comment( node ) if self.options[:debugging_comments]
		original_node = node
		previous_node = nil

		begin
			# Allow render to be delegated to subobjects
			while node.respond_to?( :render ) && node != previous_node
				self.log.debug "    delegated rendering to: %p" % [ node ]
				previous_node = node
				node = node.render( self )
			end

			if self.rendering_enabled?
				self.log.debug "  adding a %p to the destination (%p)" %
					[ node.class, self.destination.class ]
				self.destination << node
				self.log.debug "    just appended %p to %p" % [ node, self.destination ]
			end
		rescue ::StandardError => err
			self.log.debug "  handling a %p while rendering: %s" % [ err.class, err.message ]
			self.destination << self.handle_render_error( original_node, err )
		end

		return self
	end


	### Turn the rendered node structure into the final rendered String.
	def to_s
		return @output.flatten.map( &:to_s ).join
	end


	### Publish the given +nodes+ to all subscribers to the specified +key+.
	def publish( key, *nodes )
		key = key.to_sym
		self.log.debug "[0x%016x] Publishing %p nodes: %p" % [ self.object_id * 2, key, nodes ]

		self.containerstate.publish( key, *nodes ) if self.containerstate
		self.subscriptions[ key ].each do |subscriber|
			self.log.debug "  sending %d nodes to subscriber: %p (a %p)" %
				[ nodes.length, subscriber, subscriber.class ]
			subscriber.publish( *nodes )
		end
	end
	alias_method :publish_nodes, :publish


	### Subscribe the given +node+ to nodes published with the specified +key+.
	def subscribe( key, node )
		key = key.to_sym
		self.subscriptions[ key ] << node
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


	### Return a human-readable representation of the object.
	def inspect
		return "#<%p:0x%08x containerstate: %s, attributes: %s, destination: %p>" % [
			self.class,
			self.object_id / 2,
			self.containerstate ? "0x%08x" % [ self.containerstate.object_id ] : "nil",
			self.attributes.keys.sort.join(', '),
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


	### Handle attribute methods.
	def method_missing( sym, *args, &block )
		return super unless sym.to_s =~ /^[a-z]\w+[\?=!]?$/
		self.log.debug "mapping missing method call to attribute: %p" % [ sym ]
		return self.attributes[ sym ]
	end


	#######
	private
	#######

	### Recursively copy the specified +obj+ and return the result.
	def deep_copy( obj )
		Inversion.log.debug "Deep copying: %p" % [ obj ]

		# Handle mocks during testing
		return obj if obj.class.name == 'RSpec::Mocks::Mock'

		return case obj
			when NilClass, Numeric, TrueClass, FalseClass, Symbol
				obj

			when Array
				obj.map {|o| deep_copy(o) }

			when Hash
				newhash = {}
				obj.each do |k,v|
					newhash[ deep_copy(k) ] = deep_copy( v )
				end
				newhash

			else
				obj.clone
			end
	end

end # class Inversion::RenderState

