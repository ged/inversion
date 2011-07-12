#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion' unless defined?( Inversion )


# An object that tracks the progress of rendering an Inversion::Template.
#
# @author Michael Granger <ged@FaerieMUD.org>
# @author Mahlon E. Smith <mahlon@martini.nu>
#
class Inversion::RenderState
	include Inversion::Loggable

	### Create a new RenderState with the given +containerstate+, +initial_attributes+ and
	### +options+.
	def initialize( containerstate=nil, initial_attributes={}, options={} )

		# Shift hash arguments if created without a parent state
		if containerstate.is_a?( Hash )
			options = initial_attributes
			initial_attributes = containerstate
			containerstate = nil
		end

		self.log.debug "Creating a render state with attributes: %p" %
			[ initial_attributes ]

		@containerstate = containerstate
		@options        = Inversion::Template::DEFAULT_CONFIG.merge( options )
		@attributes     = [ deep_copy(initial_attributes) ]

		# The rendered output Array, and the stack of render destinations
		@output         = []
		@destinations   = [ @output ]

		# Hash of subscribed Nodes, keyed by the subscription key as a Symbol
		@subscriptions  = Hash.new {|hsh, k| hsh[k] = [] } # Auto-vivify

	end


	######
	public
	######

	# The Inversion::RenderState of the containing template, if any
	attr_reader :containerstate

	# The config options passed in from the template
	attr_reader :options

	# Subscribe placeholders for publish/subscribe
	attr_reader :subscriptions

	# The stack of rendered output destinations.
	attr_reader :destinations


	### Return the hash of attributes that are currently in effect in the
	### rendering state.
	def attributes
		return @attributes.last
	end


	### Evaluate the specified +code+ in the context of itself and
	### return the result.
	def eval( code )
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


	### Override the state's render destination, call the block, then restore the original
	### destination when the block returns.
	def with_destination( new_destination )
		raise LocalJumpError, "no block given" unless block_given?
		self.log.debug "Overriding render destination with: %p" % [ new_destination ]

		begin
			@destinations.push( new_destination )
			yield
		ensure
			@destinations.pop
		end
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
	### as an object that itself responds to the #render method, it will be called and the return 
	### value will be appended instead.
	def <<( node )
		self.log.debug "Appending node %p to %p" % [ node, self ]
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

			self.log.debug "  adding %p to the destination (%p)" % [ node, self.destination ]
			self.destination << node
		rescue => err
			self.destination << self.handle_render_error( original_node, err )
		end

		return self
	end


	### Turn the rendered node structure into the final rendered String.
	def to_s
		return @output.map( &:to_s ).join
	end


	### Publish the given +nodes+ to all subscribers to the specified +key+.
	def publish( key, *nodes )
		key = key.to_sym

		self.containerstate.publish( key, *nodes ) if self.containerstate
		self.subscriptions[ key ].each do |subscriber|
			subscriber.publish( *nodes )
		end
	end
	alias_method :publish_nodes, :publish


	### Subscribe the given +node+ to nodes published with the specified +key+.
	def subscribe( key, node )
		key = key.to_sym
		self.subscriptions[ key ] << node
	end


	### Return a human-readable representation of the object.
	def inspect
		return "#<%p:0x%08x containerstate: %s, attributes: %s, destination: %p>" % [
			self.class,
			self.object_id / 2,
			self.containerstate ? "0x%08x" % [ self.containerstate.object_id ] : "nil",
			self.attributes.keys.sort.join(', '),
			self.destination,
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


	### Handle an error while rendering according to the behavior specified by the
	### `on_render_error` option.
	### @param [Inversion::Template::Node] node  the node that caused the exception
	### @param [RuntimeError] exception  the error that was raised
	def handle_render_error( node, exception )
		self.log.error "%s while rendering %p: %s" %
			[ exception.class.name, node.as_comment_body, exception.message ]

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

