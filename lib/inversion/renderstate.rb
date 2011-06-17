#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion' unless defined?( Inversion )


# An object that tracks template attribute state through a render.
#
# @author Michael Granger <ged@FaerieMUD.org>
# @author Mahlon E. Smith <mahlon@martini.nu>
#
class Inversion::RenderState
	include Inversion::Loggable

	### Create a new RenderState with the given +initial_attributes+ and
	### +options+.
	def initialize( initial_attributes={}, options={} )
		self.log.debug "Creating a render state with attributes: %p" %
			[ initial_attributes ]

		@options    = Inversion::Template::DEFAULT_CONFIG.merge( options )
		@attributes = [ deep_copy(initial_attributes) ]
	end


	######
	public
	######

	# The config options passed in from the template
	attr_reader :options


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


	### Return the +node+ as a comment if debugging comments are enabled.
	def make_node_comment( node )
		return '' unless self.options[:debugging_comments]
		comment_body = node.as_comment_body or return ''

		return self.make_comment( comment_body )
	end


	### Handle an error while rendering according to the behavior specified by the
	### `on_render_error` option.
	### @param [Inversion::Template::Node] node  the node that caused the exception
	### @param [RuntimeError] exception  the error that was raised
	def handle_render_error( node, exception )
		self.log.error "%s while rendering %p: %s" %
			[ exception.class.name, node.as_comment_body, exception.message ]

		return case self.options[:on_render_error].to_s
			when 'ignore'
				self.log.debug "  not rendering anything for the error"
				''

			when 'comment'
				self.log.debug "  rendering error as a comment"
				msg = "%s: %s" % [ exception.class.name, exception.message ]
				self.make_comment( msg )

			when 'propagate'
				self.log.debug "  propagating error while rendering"
				raise( exception )

			else
				raise Inversion::OptionsError,
					"unknown exception-handling mode: %p" % [ self.options[:on_render_error] ]
			end
	end




	#########
	protected
	#########

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
		return super unless self.attributes.key?( sym )
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

