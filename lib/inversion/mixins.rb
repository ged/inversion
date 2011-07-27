#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:

require 'logger'


module Inversion

	# Add logging to a Inversion class. Including classes get #log and 
	# #log_debug methods.
	#
	#   class MyClass
	#       include Inversion::Loggable
	#       
	#       def a_method
	#           self.log.debug "Doing a_method stuff..."
	#       end
	#   end
	#
	module Loggable

		### A logging proxy class that wraps calls to the logger into calls that include
		### the name of the calling class.
		class ClassNameProxy # :nodoc:

			### Create a new proxy for the given +klass+.
			def initialize( klass, force_debug=false )
				@classname   = klass.name
				@force_debug = force_debug
			end

			### Delegate debug messages to the global logger with the appropriate class name.
			def debug( msg=nil, &block )
				Inversion.logger.add( Logger::DEBUG, msg, @classname, &block )
			end

			### Delegate info messages to the global logger with the appropriate class name.
			def info( msg=nil, &block )
				return self.debug( msg, &block ) if @force_debug
				Inversion.logger.add( Logger::INFO, msg, @classname, &block )
			end

			### Delegate warn messages to the global logger with the appropriate class name.
			def warn( msg=nil, &block )
				return self.debug( msg, &block ) if @force_debug
				Inversion.logger.add( Logger::WARN, msg, @classname, &block )
			end

			### Delegate error messages to the global logger with the appropriate class name.
			def error( msg=nil, &block )
				return self.debug( msg, &block ) if @force_debug
				Inversion.logger.add( Logger::ERROR, msg, @classname, &block )
			end

			### Delegate fatal messages to the global logger with the appropriate class name.
			def fatal( msg=nil, &block )
				Inversion.logger.add( Logger::FATAL, msg, @classname, &block )
			end

		end # ClassNameProxy

		#########
		protected
		#########

		### Copy constructor -- clear the original's log proxy.
		def initialize_copy( original )
			@log_proxy = @log_debug_proxy = nil
			super
		end

		### Return the proxied logger.
		def log
			@log_proxy ||= ClassNameProxy.new( self.class )
		end

		### Return a proxied "debug" logger that ignores other level specification.
		def log_debug
			@log_debug_proxy ||= ClassNameProxy.new( self.class, true )
		end

	end # module Loggable


	# Hides your class's ::new method and adds a +pure_virtual+ method generator for
	# defining API methods. If subclasses of your class don't provide implementations of
	# "pure_virtual" methods, NotImplementedErrors will be raised if they are called.
	#
	#   # AbstractClass
	#   class MyBaseClass
	#       include Inversion::AbstractClass
	#
	#       # Define a method that will raise a NotImplementedError if called
	#       pure_virtual :api_method
	#   end
	#
	module AbstractClass

		### Methods to be added to including classes
		module ClassMethods

			### Define one or more "virtual" methods which will raise
			### NotImplementedErrors when called via a concrete subclass.
			def pure_virtual( *syms )
				syms.each do |sym|
					define_method( sym ) do |*args|
						raise ::NotImplementedError,
							"%p does not provide an implementation of #%s" % [ self.class, sym ],
							caller(1)
					end
				end
			end


			### Turn subclasses' new methods back to public.
			def inherited( subclass )
				subclass.module_eval { public_class_method :new }
				super
			end

		end # module ClassMethods


		extend ClassMethods

		### Inclusion callback
		def self::included( mod )
			super
			if mod.respond_to?( :new )
				mod.extend( ClassMethods )
				mod.module_eval { private_class_method :new }
			end
		end


	end # module AbstractClass


	# A collection of utilities for working with Hashes.
	module HashUtilities

		###############
		module_function
		###############

		### Return a version of the given +hash+ with its keys transformed
		### into Strings from whatever they were before.
		###
		###    stringhash = stringify_keys( symbolhash )
		###
		def stringify_keys( hash )
			newhash = {}

			hash.each do |key,val|
				if val.is_a?( Hash )
					newhash[ key.to_s ] = stringify_keys( val )
				else
					newhash[ key.to_s ] = val
				end
			end

			return newhash
		end


		### Return a duplicate of the given +hash+ with its identifier-like keys
		### untainted and transformed into symbols from whatever they were before.
		###
		###    symbolhash = symbolify_keys( stringhash )
		###
		def symbolify_keys( hash )
			newhash = {}

			hash.each do |key,val|
				keysym = key.to_s.dup.untaint.to_sym

				if val.is_a?( Hash )
					newhash[ keysym ] = symbolify_keys( val )
				else
					newhash[ keysym ] = val
				end
			end

			return newhash
		end
		alias_method :internify_keys, :symbolify_keys

	end # module HashUtilities


	# A mixin that adds configurable escaping to a tag class.
	# 
	#   class MyTag < Inversion::Template::Tag
	#       include Inversion::Escaping
	#   
	#       def render( renderstate )
	#           val = self.get_rendered_value
	#           return self.escape( val.to_s, renderstate )
	#       end
	#   end
	#
	# To add a new kind of escaping to Inversion, add a #escape_<formatname> method to this
	# module similar to #escape_html.
	module Escaping

		# The fallback escape format
		DEFAULT_ESCAPE_FORMAT = :none


		### Escape the +output+ using the format specified by the given +render_state+'s config.
		def escape( output, render_state )
			format = render_state.options[:escape_format] || DEFAULT_ESCAPE_FORMAT
			return output if format == :none

			unless self.respond_to?( "escape_#{format}" )
				self.log.error "Format %p not supported. To add support, define a #escape_%s to %s" %
					[ format, format, __FILE__ ]
				raise Inversion::OptionsError, "No such escape format %p" % [ format ]
			end

			return self.__send__( "escape_#{format}", output )
		end


		### Escape the given +output+ using HTML entity-encoding.
		def escape_html( output )
			return output.
				gsub( /&/, '&amp;' ).
				gsub( /</, '&lt;' ).
				gsub( />/, '&gt;' )
		end

	end # Escaping

end # module Inversion

