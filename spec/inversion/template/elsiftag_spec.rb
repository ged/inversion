#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/iftag'
require 'inversion/template/elsiftag'
require 'inversion/template/unlesstag'
require 'inversion/template/textnode'
require 'inversion/renderstate'

describe Inversion::Template::ElsifTag do


	it "can be appended to an 'if' tag" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )
		iftag       = Inversion::Template::IfTag.new( 'foo' )
		elsetag     = Inversion::Template::ElsifTag.new( 'bar' )
		endtag      = Inversion::Template::EndTag.new

		parserstate << iftag << elsetag << endtag

		expect( parserstate.tree ).to eq( [ iftag, endtag ] )
	end

	it "can be appended to a 'comment' tag" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )
		commenttag  = Inversion::Template::CommentTag.new( 'else section for later' )
		elsetag     = Inversion::Template::ElsifTag.new( 'bar' )
		endtag      = Inversion::Template::EndTag.new

		parserstate << commenttag << elsetag << endtag

		expect( parserstate.tree ).to eq( [ commenttag, endtag ] )
		expect( commenttag.subnodes ).to include( elsetag )
	end

	it "raises an error if it's about to be appended to anything other than an 'if' or 'comment' tag" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )
		parserstate << Inversion::Template::UnlessTag.new( 'foo in bar' )

		expect {
			parserstate << Inversion::Template::ElsifTag.new( 'bar' )
		}.to raise_error( Inversion::ParseError, /'unless' tags can't have 'elsif' clauses/i )
	end


	it "raises an error if it's about to be appended without an opening 'if'" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )

		expect {
			parserstate << Inversion::Template::ElsifTag.new( 'bar' )
		}.to raise_error( Inversion::ParseError, /orphaned 'elsif' tag/i )
	end


	it "renders as its attribute value if it's a simple attribute" do
		renderstate = Inversion::RenderState.new( :bar => :the_attribute_value )
		tag = Inversion::Template::ElsifTag.new( 'bar' )
		expect( tag.evaluate( renderstate ) ).to eq( :the_attribute_value )
	end

end



