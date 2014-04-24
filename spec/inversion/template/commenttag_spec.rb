#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/commenttag'
require 'inversion/template/attrtag'
require 'inversion/template/textnode'
require 'inversion/renderstate'

describe Inversion::Template::CommentTag do

	it "allows any free-form text in its body" do
		# <?comment Disabled for now ?>...<?end?>
		expect( Inversion::Template::CommentTag.new('Disabled for now') ).
			to be_a( Inversion::Template::CommentTag )
	end

	it "allows an empty body" do
		# <?comment ?>...<?end?>
		expect( Inversion::Template::CommentTag.new('') ).
			to be_a( Inversion::Template::CommentTag )
	end


	it "includes information about its subnodes when rendered as a comment" do
		tag = Inversion::Template::CommentTag.new( '' )

		# - <?attr foo ?> -
		tag << Inversion::Template::TextNode.new( '- ', 1, 7 )
		tag << Inversion::Template::AttrTag.new( 'foo', 1, 9 )
		tag << Inversion::Template::TextNode.new( ' -', 1, 12 )

		expect( tag.as_comment_body ).to eq( 'Commented out 3 nodes on line 1' )
	end


	it "multiline comments include information about its subnodes when rendered as a comment" do
		tag = Inversion::Template::CommentTag.new( "We couldn't have done it without me" )

		# - <?attr foo ?> -
		tag << Inversion::Template::TextNode.new( '- ', 2, 0 )
		tag << Inversion::Template::AttrTag.new( 'foo', 3, 0 )
		tag << Inversion::Template::TextNode.new( '- ', 4, 0 )

		expect( tag.as_comment_body ).
			to eq( "Commented out 3 nodes from line 2 to 4: We couldn't have done it without me" )
	end


	it "prevents its subnodes from being rendered" do
		render_state = Inversion::RenderState.new( :plaque => %w[ten years] )
		tag = Inversion::Template::CommentTag.new( '' )

		# - <?attr foo ?> -
		tag << Inversion::Template::TextNode.new( '- ' )
		tag << Inversion::Template::AttrTag.new( 'foo' )
		tag << Inversion::Template::TextNode.new( ' -' )

		expect( tag.render(render_state) ).to eq( '' )
	end

end



