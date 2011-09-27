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
require 'inversion/template/iftag'
require 'inversion/template/elsetag'
require 'inversion/template/unlesstag'
require 'inversion/template/commenttag'
require 'inversion/template/fortag'
require 'inversion/renderstate'

describe Inversion::Template::ElseTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end

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

		parserstate.tree.should == [ iftag, endtag ]
	end

	it "can be appended to an 'unless' tag" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )
		unlesstag   = Inversion::Template::UnlessTag.new( 'foo' )
		elsetag     = Inversion::Template::ElseTag.new
		endtag      = Inversion::Template::EndTag.new

		parserstate << unlesstag << elsetag << endtag

		parserstate.tree.should == [ unlesstag, endtag ]
		unlesstag.subnodes.should include( elsetag )
	end

	it "can be appended to a 'comment' tag" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )
		commenttag  = Inversion::Template::CommentTag.new( 'else section for later' )
		elsetag     = Inversion::Template::ElseTag.new
		endtag      = Inversion::Template::EndTag.new

		parserstate << commenttag << elsetag << endtag

		parserstate.tree.should == [ commenttag, endtag ]
		commenttag.subnodes.should include( elsetag )
	end

	it "raises an error if it's about to be appended to anything other than an 'if', 'unless', " +
	   "or 'comment' tag" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )
		parserstate << Inversion::Template::ForTag.new( 'foo in bar' )

		expect {
			parserstate << Inversion::Template::ElseTag.new
		}.to raise_exception( Inversion::ParseError, /'for' tags can't have 'else' clauses/i )
	end


	it "raises an error if it's about to be appended without an opening 'if' or 'unless'" do
		template    = double( "template object" )
		parserstate = Inversion::Parser::State.new( template )

		expect {
			parserstate << Inversion::Template::ElseTag.new
		}.to raise_exception( Inversion::ParseError, /orphaned 'else' tag/i )
	end


	it "doesn't render as anything by itself" do
		renderstate = Inversion::RenderState.new
		tag = Inversion::Template::ElseTag.new
		tag.render( renderstate ).should be_nil()
	end

end



