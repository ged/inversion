#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'spec/lib/helpers'
require 'inversion'

describe Inversion do

	before( :all ) do
		@original_logger = Inversion.default_logger
		@original_log_formatter = Inversion.default_log_formatter
		setup_logging( :fatal )
	end

	after( :each ) do
		Inversion.default_logger = @original_logger
		Inversion.default_log_formatter = @original_log_formatter
		reset_logging()
	end


	it "defines a version" do
		Inversion::VERSION.should =~ /^\d+(\.\d+)*$/
	end

	describe "version methods" do

		it "returns a version string if asked" do
			Inversion.version_string.should =~ /\w+ [\d.]+/
		end

		it "returns a version string with a build number if asked" do
			Inversion.version_string(true).should =~ /\w+ [\d.]+ \(build [[:xdigit:]]+\)/
		end
	end


	describe " logging subsystem" do
		before(:each) do
			Inversion.reset_logger
		end

		after(:each) do
			Inversion.reset_logger
		end


		it "knows if its default logger is replaced" do
			Inversion.reset_logger
			Inversion.should be_using_default_logger
			Inversion.logger = Logger.new( $stderr )
			Inversion.should_not be_using_default_logger
		end

		it "has the default logger instance after being reset" do
			Inversion.logger.should equal( Inversion.default_logger )
		end

		it "has the default log formatter instance after being reset" do
			Inversion.logger.formatter.should equal( Inversion.default_log_formatter )
		end

	end


	describe " logging subsystem with new defaults" do
		it "uses the new defaults when the logging subsystem is reset" do
			logger = double( "dummy logger" )
			formatter = double( "dummy logger" )

			Inversion.default_logger = logger
			Inversion.default_log_formatter = formatter

			logger.should_receive( :formatter= ).with( formatter )
			logger.should_receive( :level= ).with( Logger::WARN )

			Inversion.reset_logger
			Inversion.logger.should equal( logger )
		end

	end


end

