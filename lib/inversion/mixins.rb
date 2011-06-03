#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:

require 'logger'


module Inversion

	### Add logging to a Inversion class. Including classes get #log and #log_debug methods.
	module Loggable

		### A logging proxy class that wraps calls to the logger into calls that include
		### the name of the calling class.
		### @private
		class ClassNameProxy

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


	### A collection of ANSI color utility functions
	module ANSIColorUtilities

		# Set some ANSI escape code constants (Shamelessly stolen from Perl's
		# Term::ANSIColor by Russ Allbery <rra@stanford.edu> and Zenin <zenin@best.com>
		ANSI_ATTRIBUTES = {
			'clear'      => 0,
			'reset'      => 0,
			'bold'       => 1,
			'dark'       => 2,
			'underline'  => 4,
			'underscore' => 4,
			'blink'      => 5,
			'reverse'    => 7,
			'concealed'  => 8,

			'black'      => 30,   'on_black'   => 40,
			'red'        => 31,   'on_red'     => 41,
			'green'      => 32,   'on_green'   => 42,
			'yellow'     => 33,   'on_yellow'  => 43,
			'blue'       => 34,   'on_blue'    => 44,
			'magenta'    => 35,   'on_magenta' => 45,
			'cyan'       => 36,   'on_cyan'    => 46,
			'white'      => 37,   'on_white'   => 47
		}

		###############
		module_function
		###############

		### Create a string that contains the ANSI codes specified and return it
		def ansi_code( *attributes )
			attributes.flatten!
			attributes.collect! {|at| at.to_s }
			return '' unless /(?:vt10[03]|xterm(?:-color)?|linux|screen)/i =~ ENV['TERM']
			attributes = ANSI_ATTRIBUTES.values_at( *attributes ).compact.join(';')

			if attributes.empty?
				return ''
			else
				return "\e[%sm" % attributes
			end
		end


		### Colorize the given +string+ with the specified +attributes+ and
		### return it, handling line-endings, color reset, etc.
		def colorize( *args )
			string = ''

			if block_given?
				string = yield
			else
				string = args.shift
			end

			ending = string[/(\s)$/] || ''
			string = string.rstrip

			return ansi_code( args.flatten ) + string + ansi_code( 'reset' ) + ending
		end

	end # module ANSIColorUtilities


	### Hides your class's ::new method and adds a method generator called 'pure_virtual' for
	### defining API methods. If subclasses of your class don't provide implementations of
	### "pure_virtual" methods, NotImplementedErrors will be raised if they are called.
	###
	###   # AbstractClass
	###   class MyBaseClass
	###       include Inversion::AbstractClass
	###
	###       # Define a method that will raise a NotImplementedError if called
	###       pure_virtual :api_method
	###   end
	###
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
end # module Inversion

