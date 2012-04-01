#!/usr/bin/ruby
# coding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

# SimpleCov test coverage reporting; enable this using the :coverage rake task
if ENV['COVERAGE']
	require 'simplecov'
	SimpleCov.start do
		add_filter 'spec'
		add_group "Tags" do |file|
			file.filename =~ /tag.rb$/
		end
		add_group "Needing tests" do |file|
			file.covered_percent < 90
		end
	end
end

require 'rspec'

require 'inversion'
require 'spec/lib/constants'

### IRb.start_session, courtesy of Joel VanderWerf in [ruby-talk:42437].
require 'irb'
require 'irb/completion'


module IRB # :nodoc:
	def self.start_session( obj )
		unless @__initialized
			args = ARGV
			ARGV.replace( ARGV.dup )
			IRB.setup( nil )
			ARGV.replace( args )
			@__initialized = true
		end

		workspace = WorkSpace.new( obj )
		irb = Irb.new( workspace )

		@CONF[:IRB_RC].call( irb.context ) if @CONF[:IRB_RC]
		@CONF[:MAIN_CONTEXT] = irb.context

		begin
			prevhandler = Signal.trap( 'INT' ) do
				irb.signal_handle
			end

			catch( :IRB_EXIT ) do
				irb.eval_input
			end
		ensure
			Signal.trap( 'INT', prevhandler )
		end

	end
end


### RSpec helper functions.
module Inversion::SpecHelpers
	include Inversion::TestConstants

	class ArrayLogger
		### Create a new ArrayLogger that will append content to +array+.
		def initialize( array )
			@array = array
		end

		### Write the specified +message+ to the array.
		def write( message )
			@array << message
		end

		### No-op -- this is here just so Logger doesn't complain
		def close; end

	end # class ArrayLogger


	unless defined?( LEVEL )
		LEVEL = {
			:debug => Logger::DEBUG,
			:info  => Logger::INFO,
			:warn  => Logger::WARN,
			:error => Logger::ERROR,
			:fatal => Logger::FATAL,
		  }
	end

	###############
	module_function
	###############

	### Make an easily-comparable version vector out of +ver+ and return it.
	def vvec( ver )
		return ver.split('.').collect {|char| char.to_i }.pack('N*')
	end


	### Reset the logging subsystem to its default state.
	def reset_logging
		Inversion.reset_logger
	end


	### Alter the output of the default log formatter to be pretty in SpecMate output
	def setup_logging( level=Logger::FATAL )

		# Turn symbol-style level config into Logger's expected Fixnum level
		if Inversion::Logging::LOG_LEVELS.key?( level.to_s )
			level = Inversion::Logging::LOG_LEVELS[ level.to_s ]
		end

		logger = Logger.new( $stderr )
		Inversion.logger = logger
		Inversion.logger.level = level

		# Only do this when executing from a spec in TextMate
		if ENV['HTML_LOGGING'] || (ENV['TM_FILENAME'] && ENV['TM_FILENAME'] =~ /_spec\.rb/)
			Thread.current['logger-output'] = []
			logdevice = ArrayLogger.new( Thread.current['logger-output'] )
			Inversion.logger = Logger.new( logdevice )
			# Inversion.logger.level = level
			Inversion.logger.formatter = Inversion::Logging::HtmlFormatter.new( logger )
		end
	end


	### Create a string containing an XML Processing Instruction with the given +name+
	### and +data+.
	def create_pi( name, data )
		return "<?#{name} #{data} ?>"
	end


end


### Mock with RSpec
RSpec.configure do |c|
	include Inversion::TestConstants

	c.mock_with :rspec
	c.include( Inversion::SpecHelpers )
	c.filter_run_excluding( :ruby_1_9_only => true ) if
		Inversion::SpecHelpers.vvec( RUBY_VERSION ) < Inversion::SpecHelpers.vvec('1.9.0')
end

# vim: set nosta noet ts=4 sw=4:

