#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:

require 'tempfile'

module Inversion

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
			return output.to_s.
				gsub( /&/, '&amp;' ).
				gsub( /</, '&lt;' ).
				gsub( />/, '&gt;' )
		end

	end # Escaping


	# A collection of methods for declaring other methods.
	#
	#   class MyClass
	#       include Inversion::MethodUtilities
	#
	#       singleton_attr_accessor :types
	#   end
	#
	#   MyClass.types = [ :pheno, :proto, :stereo ]
	#
	module MethodUtilities

		### Creates instance variables and corresponding methods that return their
		### values for each of the specified +symbols+ in the singleton of the
		### declaring object (e.g., class instance variables and methods if declared
		### in a Class).
		def singleton_attr_reader( *symbols )
			symbols.each do |sym|
				singleton_class.__send__( :attr_reader, sym )
			end
		end

		### Creates methods that allow assignment to the attributes of the singleton
		### of the declaring object that correspond to the specified +symbols+.
		def singleton_attr_writer( *symbols )
			symbols.each do |sym|
				singleton_class.__send__( :attr_writer, sym )
			end
		end

		### Creates readers and writers that allow assignment to the attributes of
		### the singleton of the declaring object that correspond to the specified
		### +symbols+.
		def singleton_attr_accessor( *symbols )
			symbols.each do |sym|
				singleton_class.__send__( :attr_accessor, sym )
			end
		end

	end # module MethodUtilities


	# A collection of data-manipulation functions.
	module DataUtilities

		###############
		module_function
		###############

		### Recursively copy the specified +obj+ and return the result.
		def deep_copy( obj )
			# self.log.debug "Deep copying: %p" % [ obj ]

			# Handle mocks during testing
			return obj if obj.class.name == 'RSpec::Mocks::Mock'

			return case obj
				when NilClass, Numeric, TrueClass, FalseClass, Symbol,
				     Module, Encoding, IO, Tempfile
					obj

				when Array
					obj.map {|o| deep_copy(o) }

				when Hash
					newhash = {}
					newhash.default_proc = obj.default_proc if obj.default_proc
					obj.each do |k,v|
						newhash[ deep_copy(k) ] = deep_copy( v )
					end
					newhash

				else
					obj.clone
				end
		end

	end # module DataUtilities

end # module Inversion

