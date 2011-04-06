#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent.parent.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'spec/lib/helpers'
require 'inversion/template/calltag'

describe Inversion::Template::CallTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	it "supports simple <identifier>.<methodname> syntax" do
		tag = Inversion::Template::CallTag.new( 'foo.bar' )

		tag.attribute.should == 'foo'
		tag.methodchain.should == [['bar']]
	end


	it "supports <identifier>.<methodname>( arguments ) syntax" do
		tag = Inversion::Template::CallTag.new( 'foo.bar( 8, :baz )' )

		tag.attribute.should == 'foo'
		tag.methodchain.should == [[ 'bar', '8, :baz' ]]
	end

end
