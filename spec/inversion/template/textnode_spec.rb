#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/textnode'

describe Inversion::Template::TextNode do

	before( :each ) do
		@state = Inversion::RenderState.new
		@node = Inversion::Template::TextNode.new( "unto thee" )
	end


	it "renders itself unchanged" do
		expect( @node.render( @state ) ).to eq( "unto thee" )
	end

	it "renders a brief description when rendered as a comment" do
		expect( @node.as_comment_body ).to eq( %{Text (9 bytes): "unto thee"} )
	end


	context "beginning with a newline and containing only whitespace" do
		before( :each ) do
			@text = "\n\tSome stuff\nAnd some other stuff.\n  "
			@node.instance_variable_set( :@body, @text )
		end

		it "strips the leading newline if :strip_tag_lines is set" do
			@state.options[:strip_tag_lines] = true
			expect( @node.render( @state ) ).to eq( "\tSome stuff\nAnd some other stuff.\n  " )
		end

		it "renders as-is if :strip_tag_lines is not set" do
			@state.options[:strip_tag_lines] = false
			expect( @node.render( @state ) ).to eq( @text )
		end

	end


	context "with more than 40 bytes of content" do

		LONGER_CONTENT = <<-END_CONTENT
		<p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt
        ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco
        laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in
        voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat
        cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
		END_CONTENT

		before( :each ) do
			@node.instance_variable_set( :@body, LONGER_CONTENT )
		end

		it "renders only the first 40 bytes when rendered as a comment" do
			expected_content = LONGER_CONTENT[0,40].dump
			expected_content[-1,0] = '...'

			expect(
				@node.as_comment_body
			).to eq( %Q{Text (488 bytes): "\\t\\t<p>Lorem ipsum dolor sit amet, consect..."} )
		end

	end

end

