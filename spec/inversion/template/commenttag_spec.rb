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
require 'inversion/template/commenttag'
require 'inversion/template/attrtag'
require 'inversion/template/textnode'
require 'inversion/renderstate'

describe Inversion::Template::CommentTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	it "allows any free-form text in its body" do
		# <?comment Disabled for now ?>...<?end?>
		Inversion::Template::CommentTag.new( 'Disabled for now' ).
			should be_a( Inversion::Template::CommentTag )
	end

	it "allows an empty body" do
		# <?comment ?>...<?end?>
		Inversion::Template::CommentTag.new( '' ).
			should be_a( Inversion::Template::CommentTag )
	end


	it "includes information about its subnodes when rendered as a comment" do
		tag = Inversion::Template::CommentTag.new( '' )

		# - <?attr foo ?> -
		tag << Inversion::Template::TextNode.new( '- ', 1, 7 )
		tag << Inversion::Template::AttrTag.new( 'foo', 1, 9 )
		tag << Inversion::Template::TextNode.new( ' -', 1, 12 )

		tag.as_comment_body.should == 'Commented out 3 nodes on line 1'
	end


	it "multiline comments include information about its subnodes when rendered as a comment" do
		tag = Inversion::Template::CommentTag.new( "We couldn't have done it without me" )

		# - <?attr foo ?> -
		tag << Inversion::Template::TextNode.new( '- ', 2, 0 )
		tag << Inversion::Template::AttrTag.new( 'foo', 3, 0 )
		tag << Inversion::Template::TextNode.new( '- ', 4, 0 )

		tag.as_comment_body.should == "Commented out 3 nodes from line 2 to 4: " +
			"We couldn't have done it without me"
	end


	it "prevents its subnodes from being rendered" do
		render_state = Inversion::RenderState.new( :plaque => %w[ten years] )
		tag = Inversion::Template::CommentTag.new( '' )

		# - <?attr foo ?> -
		tag << Inversion::Template::TextNode.new( '- ' )
		tag << Inversion::Template::AttrTag.new( 'foo' )
		tag << Inversion::Template::TextNode.new( ' -' )

		tag.render( render_state ).should == ''
	end

end



