#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'stringio'
require 'inversion/template'

describe Inversion::Template do

	it "can be loaded from a String" do
		Inversion::Template.new( "a template" ).source.should == 'a template'
	end

	it "can be loaded from an IO" do
		io = StringIO.new( 'a template' )
		Inversion::Template.new( io ).source.should == 'a template'
	end

	it "renders the source as-is if there are no instructions" do
		Inversion::Template.new( "a template" ).render.should == 'a template'
	end

end

