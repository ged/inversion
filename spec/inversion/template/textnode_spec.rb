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
require 'inversion/template/textnode'

describe Inversion::Template::TextNode do

	before( :all ) do
		setup_logging( :fatal )
	end

	before( :each ) do
		@state = Inversion::RenderState.new
		@node = Inversion::Template::TextNode.new( "unto thee" )
	end

	after( :all ) do
		reset_logging()
	end


	it "renders itself unchanged" do
		@node.render( @state ).should == "unto thee"
	end

	it "renders a brief description when rendered as a comment" do
		@node.as_comment_body.should == %{Text (9 bytes): "unto thee"}
	end


	context "beginning with a newline and containing only whitespace" do
		before( :each ) do
			@text = "\n\tSome stuff\nAnd some other stuff.\n  "
			@node.instance_variable_set( :@body, @text )
		end

		it "strips the leading newline if :strip_tag_lines is set" do
			@state.options[:strip_tag_lines] = true
			@node.render( @state ).should == "\tSome stuff\nAnd some other stuff.\n  "
		end

		it "renders as-is if :strip_tag_lines is not set" do
			@state.options[:strip_tag_lines] = false
			@node.render( @state ).should == @text
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

			@node.as_comment_body.should ==
				%Q{Text (488 bytes): "\\t\\t<p>Lorem ipsum dolor sit amet, consect..."}
		end

	end

end

