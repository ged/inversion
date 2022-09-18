# -*- ruby -*-
# vim: set noet nosta sw=4 ts=4 :

require 'pp'

# In order to support more-functional tag contents without scope bleed,
# I need an object that's kind of a cross between a Hash and a Binding. This is
# an experiment to work out that idea.


class Scope < BasicObject

	def initialize( hash )
		@locals = hash
	end

	def method_missing( sym, *args, &block )
		return super unless sym =~ /^\w+$/
		@locals[ sym ]
	end

	def eval( string )
		$stderr.puts "Evaling: %p" % [ string ]
		return instance_eval( string, "tag", 1 )
	end

	def []( key )
		return @locals[ key.to_sym ]
	end

	def []=( key, val )
		@locals[ key.to_sym ] = val
	end

end # class Scope


scope = Scope.new( a: 117, b: '__id__', c: Object.new )

pp scope.eval( "a * 4 > 80" )
pp scope.eval( "b * a" )
pp scope.eval( "c.__send__( b )" )
pp scope.eval( "a && b && c" )

scope[ :foom ] = "Yeah, you heard me."
pp scope.eval( "foom.reverse" )
