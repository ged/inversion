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
require 'loggability'

require 'inversion'
require 'spec/lib/constants'


### RSpec helper functions.
module Inversion::SpecHelpers
	include Inversion::TestConstants

	###############
	module_function
	###############

	### Make an easily-comparable version vector out of +ver+ and return it.
	def vvec( ver )
		return ver.split('.').collect {|char| char.to_i }.pack('N*')
	end


	### Reset the logging subsystem to its default state.
	def reset_logging
		Loggability.formatter = nil
		Loggability.output_to( $stderr )
		Loggability.level = :fatal
	end


	### Alter the output of the default log formatter to be pretty in SpecMate output
	def setup_logging( level=:fatal )

		# Only do this when executing from a spec in TextMate
		if ENV['HTML_LOGGING'] || (ENV['TM_FILENAME'] && ENV['TM_FILENAME'] =~ /_spec\.rb/)
			$stderr.puts "Setting up HTML logs."
			logarray = []
			Thread.current['logger-output'] = logarray
			Loggability.output_to( logarray )
			Loggability.format_as( :html )
			Loggability.level = :debug
		else
			Loggability.level = level
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

