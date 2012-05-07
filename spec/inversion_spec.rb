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
		setup_logging( :fatal )
	end

	after( :each ) do
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

end

