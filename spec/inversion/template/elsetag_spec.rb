#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/iftag'
require 'inversion/template/elsetag'
require 'inversion/template/unlesstag'
require 'inversion/template/commenttag'
require 'inversion/template/fortag'
require 'inversion/renderstate'

describe Inversion::Template::ElseTag do

	it "handles a non-existant body" do
		Inversion::Template::ElseTag.new( nil )
	end

	it "can be appended to an 'if' tag" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )
		iftag       = Inversion::Template::IfTag.new( 'foo' )
		elsetag     = Inversion::Template::ElseTag.new
		endtag      = Inversion::Template::EndTag.new

		parserstate << iftag << elsetag << endtag

		expect( parserstate.tree ).to eq( [ iftag, endtag ] )
	end

	it "can be appended to an 'unless' tag" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )
		unlesstag   = Inversion::Template::UnlessTag.new( 'foo' )
		elsetag     = Inversion::Template::ElseTag.new
		endtag      = Inversion::Template::EndTag.new

		parserstate << unlesstag << elsetag << endtag

		expect( parserstate.tree ).to eq( [ unlesstag, endtag ] )
		expect( unlesstag.subnodes ).to include( elsetag )
	end

	it "can be appended to a 'comment' tag" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )
		commenttag  = Inversion::Template::CommentTag.new( 'else section for later' )
		elsetag     = Inversion::Template::ElseTag.new
		endtag      = Inversion::Template::EndTag.new

		parserstate << commenttag << elsetag << endtag

		expect( parserstate.tree ).to eq( [ commenttag, endtag ] )
		expect( commenttag.subnodes ).to include( elsetag )
	end

	it "raises an error if it's about to be appended to anything other than an 'if', 'unless', " +
	   "or 'comment' tag" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )
		parserstate << Inversion::Template::ForTag.new( 'foo in bar' )

		expect {
			parserstate << Inversion::Template::ElseTag.new
		}.to raise_error( Inversion::ParseError, /'for' tags can't have 'else' clauses/i )
	end


	it "raises an error if it's about to be appended without an opening 'if' or 'unless'" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )

		expect {
			parserstate << Inversion::Template::ElseTag.new
		}.to raise_error( Inversion::ParseError, /orphaned 'else' tag/i )
	end


	it "doesn't render as anything by itself" do
		renderstate = Inversion::RenderState.new
		tag = Inversion::Template::ElseTag.new
		expect( tag.render(renderstate) ).to be_nil()
	end

end



