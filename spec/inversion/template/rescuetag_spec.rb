#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/begintag'
require 'inversion/template/rescuetag'
require 'inversion/template/commenttag'
require 'inversion/template/fortag'
require 'inversion/renderstate'

describe Inversion::Template::RescueTag do

	it "handles a non-existant body" do
		tag = Inversion::Template::RescueTag.new( nil )
		expect( tag.exception_types ).to eq( [ ::RuntimeError ] )
	end

	it "parses its body into classes" do
		tag = Inversion::Template::RescueTag.new( 'ScriptError' )
		expect( tag.exception_types ).to eq( [ ::ScriptError ] )
	end

	it "handles fully-qualified class names" do
		tag = Inversion::Template::RescueTag.new( '::ScriptError' )
		expect( tag.exception_types ).to eq( [ ::ScriptError ] )
	end

	it "can parse multiple exception class names" do
		tag = Inversion::Template::RescueTag.new( '::ScriptError, Inversion::ParseError' )
		expect( tag.exception_types ).to eq( [ ::ScriptError, Inversion::ParseError ] )
	end

	it "can be appended to a 'begin' tag" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )
		begintag    = Inversion::Template::BeginTag.new
		rescuetag   = Inversion::Template::RescueTag.new
		textnode    = Inversion::Template::TextNode.new( 'Yeah!' )
		endtag      = Inversion::Template::EndTag.new

		parserstate << begintag << rescuetag << textnode << endtag

		expect( parserstate.tree ).to eq( [ begintag, endtag ] )
		expect( begintag.rescue_clauses ).to eq( [ [[::RuntimeError], [textnode]] ] )
	end

	it "can be appended to a 'comment' tag" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )
		commenttag  = Inversion::Template::CommentTag.new( 'rescue section for later' )
		rescuetag   = Inversion::Template::RescueTag.new
		endtag      = Inversion::Template::EndTag.new

		parserstate << commenttag << rescuetag << endtag

		expect( parserstate.tree ).to eq( [ commenttag, endtag ] )
		expect( commenttag.subnodes ).to include( rescuetag )
	end

	it "raises an error if it's about to be appended to anything other than a 'begin' or " +
	   "'comment' tag" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )
		parserstate << Inversion::Template::ForTag.new( 'foo in bar' )

		expect {
			parserstate << Inversion::Template::RescueTag.new
		}.to raise_error( Inversion::ParseError, /'for' tags can't have 'rescue' clauses/i )
	end


	it "raises an error if it's about to be appended without an opening 'begin'" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )

		expect {
			parserstate << Inversion::Template::RescueTag.new
		}.to raise_error( Inversion::ParseError, /orphaned 'rescue' tag/i )
	end


	it "doesn't render as anything by itself" do
		renderstate = Inversion::RenderState.new
		tag = Inversion::Template::RescueTag.new
		expect( tag.render( renderstate ) ).to be_nil()
	end

end



