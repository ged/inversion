#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent.parent
	libdir  = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s )  unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'stringio'

require 'spec/lib/helpers'

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

	context "with an attribute tag" do

		let( :template ) { Inversion::Template.new("<h1><?attr foo ?></h1>") }


		it "has a reader for getting the tag's value" do
			template.should respond_to( :foo )
		end

		it "has an accessor for setting the tag's value" do
			template.should respond_to( :foo= )
		end

		it "renders scalar values set for the tag" do
			template.foo = "a lion"
			template.render.should == "<h1>a lion</h1>"
		end

		it "renders an non-String value set for the tag using #to_s" do
			template.foo = [ 'a lion', 'a little guy', 'a bad mousie', 'one birdy' ]
			template.render.should == %{<h1>["a lion", "a little guy", "a bad mousie", "one birdy"]</h1>}
		end
	end
end

