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
require 'inversion/template/unlesstag'
require 'inversion/template/textnode'
require 'inversion/renderstate'

describe Inversion::Template::UnlessTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	it "renders its contents if its attribute is false" do
		tag = Inversion::Template::UnlessTag.new( 'attribute' )
		tag << Inversion::Template::TextNode.new( 'the body' )

		renderstate = Inversion::RenderState.new( :attribute => false )
		tag.render( renderstate ).to_s.should == 'the body'
	end

	it "renders its contents if its methodchain is false" do
		tag = Inversion::Template::UnlessTag.new( 'attribute.key?(:foo)' )
		tag << Inversion::Template::TextNode.new( 'the body' )

		renderstate = Inversion::RenderState.new( :attribute => {:bar => 1} )
		tag.render( renderstate ).to_s.should == 'the body'
	end

	it "doesn't render its contents if its attribute is true" do
		tag = Inversion::Template::UnlessTag.new( 'attribute' )
		tag << Inversion::Template::TextNode.new( 'the body' )

		renderstate = Inversion::RenderState.new( :attribute => true )
		tag.render( renderstate ).to_s.should == ''
	end

	it "doesn't render its contents if its methodchain is true" do
		tag = Inversion::Template::UnlessTag.new( 'attribute.key?(:foo)' )
		tag << Inversion::Template::TextNode.new( 'the body' )

		renderstate = Inversion::RenderState.new( :attribute => {:foo => 1} )
		tag.render( renderstate ).to_s.should == ''
	end

	context "with an 'else' clause" do

		before( :each ) do
			@tag = Inversion::Template::UnlessTag.new( 'attribute' )
			@tag << Inversion::Template::TextNode.new( 'the body before else' )
			@tag << Inversion::Template::ElseTag.new
			@tag << Inversion::Template::TextNode.new( 'the body after else' )

		end

		it "only renders the second half of the contents if its attribute is true" do
			renderstate = Inversion::RenderState.new( :attribute => true )
			@tag.render( renderstate ).to_s.should == 'the body after else'
		end

		it "only renders the first half of the contents if its attribute is false" do
			renderstate = Inversion::RenderState.new( :attribute => false )
			@tag.render( renderstate ).to_s.should == 'the body before else'
		end

	end

end
