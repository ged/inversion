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
require 'inversion/template/begintag'
require 'inversion/template/rescuetag'
require 'inversion/template/commenttag'
require 'inversion/template/fortag'
require 'inversion/renderstate'

describe Inversion::Template::RescueTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end

	it "handles a non-existant body" do
		tag = Inversion::Template::RescueTag.new( nil )
		tag.exception_types.should == [ ::RuntimeError ]
	end

	it "parses its body into classes" do
		tag = Inversion::Template::RescueTag.new( 'ScriptError' )
		tag.exception_types.should == [ ::ScriptError ]
	end

	it "handles fully-qualified class names" do
		tag = Inversion::Template::RescueTag.new( '::ScriptError' )
		tag.exception_types.should == [ ::ScriptError ]
	end

	it "can parse multiple exception class names" do
		tag = Inversion::Template::RescueTag.new( '::ScriptError, Inversion::ParseError' )
		tag.exception_types.should == [ ::ScriptError, Inversion::ParseError ]
	end

	it "can be appended to a 'begin' tag" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )
		begintag    = Inversion::Template::BeginTag.new
		rescuetag   = Inversion::Template::RescueTag.new
		textnode    = Inversion::Template::TextNode.new( 'Yeah!' )
		endtag      = Inversion::Template::EndTag.new

		parserstate << begintag << rescuetag << textnode << endtag

		parserstate.tree.should == [ begintag, endtag ]
		begintag.rescue_clauses.should == [ [[::RuntimeError], [textnode]] ]
	end

	it "can be appended to a 'comment' tag" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )
		commenttag  = Inversion::Template::CommentTag.new( 'rescue section for later' )
		rescuetag   = Inversion::Template::RescueTag.new
		endtag      = Inversion::Template::EndTag.new

		parserstate << commenttag << rescuetag << endtag

		parserstate.tree.should == [ commenttag, endtag ]
		commenttag.subnodes.should include( rescuetag )
	end

	it "raises an error if it's about to be appended to anything other than a 'begin' or " +
	   "'comment' tag" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )
		parserstate << Inversion::Template::ForTag.new( 'foo in bar' )

		expect {
			parserstate << Inversion::Template::RescueTag.new
		}.to raise_exception( Inversion::ParseError, /'for' tags can't have 'rescue' clauses/i )
	end


	it "raises an error if it's about to be appended without an opening 'begin'" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )

		expect {
			parserstate << Inversion::Template::RescueTag.new
		}.to raise_exception( Inversion::ParseError, /orphaned 'rescue' tag/i )
	end


	it "doesn't render as anything by itself" do
		renderstate = Inversion::RenderState.new
		tag = Inversion::Template::RescueTag.new
		tag.render( renderstate ).should be_nil()
	end

end



