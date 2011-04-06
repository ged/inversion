#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent.parent.parent
	libdir  = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s )  unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'spec/lib/helpers'
require 'inversion/template/parser'

describe Inversion::Template::Parser do

	before( :all ) do
		setup_logging( :fatal )
		Inversion::Template::Tag.load_all
	end

	it "parses a string with no PIs as a single text node" do
		result = Inversion::Template::Parser.new.parse( "render unto Caesar" )

		result.should have( 1 ).member
		result.first.should be_a( Inversion::Template::TextNode )
		result.first.source.should == 'render unto Caesar'
	end

	it "parses an empty string as a empty tree" do
		result = Inversion::Template::Parser.new.parse( "" )
		result.should be_empty
	end

	it "parses a string with a single 'attr' tag as a single AttrTag node" do
		Inversion.log.debug "Types: %p" % [ Inversion::Template::Tag.types ]
		Inversion.log.debug "Derivatives: %p" % [ Inversion::Template::Tag.derivatives ]
		Inversion.log.debug "LOADED_FEATURES: %p" % [ $LOADED_FEATURES ]

		result = Inversion::Template::Parser.new.parse( "<?attr foo ?>" )

		result.should have( 1 ).member
		result.first.should be_a( Inversion::Template::AttrTag )
		result.first.body.should == 'foo'
	end

	it "parses a single 'attr' tag surrounded by plain text" do
		result = Inversion::Template::Parser.new.parse( "beginning<?attr foo ?>end" )

		result.should have( 3 ).members
		result[0].should be_a( Inversion::Template::TextNode )
		result[1].should be_a( Inversion::Template::AttrTag )
		result[1].body.should == 'foo'
		result[2].should be_a( Inversion::Template::TextNode )
	end

	it "can ignore unknown tags"
	it "can raise exceptions on unknown tags"

end

