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

	### Create a new RenderState with the given +initial_attributes+.
	def initialize( initial_attributes={} )
		self.log.debug "Creating a render state with attributes: %p" %
			[ initial_attributes ]
		@attributes = [ deep_copy(initial_attributes) ]
	end


	######
	public
	######

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


	#########
	protected
	#########

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
				obj.dup
			end
	end

end # class Inversion::RenderState

