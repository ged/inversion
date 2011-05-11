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
require 'inversion/template/attrtag'

describe Inversion::Template::AttrTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	it "can have a simple attribute name" do
		Inversion::Template::AttrTag.new( 'foo' ).name.should == 'foo'
	end

	it "can have an attribute name and a format string" do
		Inversion::Template::AttrTag.new( '"%0.2f" % foo' ).name.should == 'foo'
	end

	it "raises an exception with an unknown operator" do
		expect {
			Inversion::Template::AttrTag.new( '"%0.2f" + foo' )
		}.to raise_exception( Inversion::ParseError, /expected/ )
	end

	it "raises an exception if it has more than one identifier" do
		expect {
			Inversion::Template::AttrTag.new( '"%0.2f" % [ foo, bar ]' )
		}.to raise_exception( Inversion::ParseError, /expected/ )
	end

	describe "without a format" do

		before( :each ) do
			@tag = Inversion::Template::AttrTag.new( 'foo' )
		end

		it "renders as the stringified contents of the template attribute with the same name" do
			attributes = double( "template object attributes" )
			template = stub( "template object", :attributes => attributes )

			attributes.should_receive( :[] ).with( :foo ).and_return([ "floppy", "the", "turtle" ])

			@tag.render( template ).should == %{["floppy", "the", "turtle"]}
		end

		it "doesn't error if the attribute isn't set on the template" do
			attributes = double( "template object attributes" )
			template = stub( "template object", :attributes => attributes )

			attributes.should_receive( :[] ).with( :foo ).and_return( nil )

			@tag.render( template ).should == ''
		end

		it "can render itself as a comment for template debugging" do
			@tag.as_comment_body.should == %{Attr "foo"}
		end

	end

	describe "with a format" do

		before( :each ) do
			@tag = Inversion::Template::AttrTag.new( 'foo' )
			@tag.format = "%0.2f"
		end

		it "renders as the formatted contents of the template attribute with the same name" do
			attributes = double( "template object attributes" )
			template = stub( "template object", :attributes => attributes )

			attributes.should_receive( :[] ).with( :foo ).and_return( Math::PI )

			@tag.render( template ).should == '3.14'
		end

		it "doesn't error if the attribute isn't set on the template" do
			attributes = double( "template object attributes" )
			template = stub( "template object", :attributes => attributes )

			attributes.should_receive( :[] ).with( :foo ).and_return( nil )

			@tag.render( template ).should == ''
		end

		it "can render itself as a comment for template debugging" do
			@tag.as_comment_body.should == %Q{Attr "foo" with format: "%0.2f"}
		end

	end

end


