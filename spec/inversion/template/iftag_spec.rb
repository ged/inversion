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
require 'inversion/template/textnode'
require 'inversion/renderstate'

describe Inversion::Template::IfTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	it "renders its contents if its attribute is true" do
		tag = Inversion::Template::IfTag.new( 'attribute' )
		tag << Inversion::Template::TextNode.new( 'the body' )

		renderstate = Inversion::RenderState.new( :attribute => true )
		tag.render( renderstate ).to_s.should == 'the body'
	end


	it "renders its contents if its methodchain is true" do
		tag = Inversion::Template::IfTag.new( 'attribute.key?(:foo)' )
		tag << Inversion::Template::TextNode.new( 'the body' )

		renderstate = Inversion::RenderState.new( :attribute => {:foo => 1} )
		tag.render( renderstate ).to_s.should == 'the body'
	end

	it "doesn't render its contents if its attribute is false" do
		tag = Inversion::Template::IfTag.new( 'attribute' )
		tag << Inversion::Template::TextNode.new( 'the body' )

		renderstate = Inversion::RenderState.new( :attribute => nil )
		tag.render( renderstate ).to_s.should == ''
	end

	it "doesn't render its contents if its methodchain is false" do
		tag = Inversion::Template::IfTag.new( 'attribute.key?(:foo)' )
		tag << Inversion::Template::TextNode.new( 'the body' )

		renderstate = Inversion::RenderState.new( :attribute => {:bar => 1} )
		tag.render( renderstate ).to_s.should == ''
	end

	context "with a single 'else' clause" do

		before( :each ) do
			@tag = Inversion::Template::IfTag.new( 'attribute' )
			@tag << Inversion::Template::TextNode.new( 'the body before else' )
			@tag << Inversion::Template::ElseTag.new
			@tag << Inversion::Template::TextNode.new( 'the body after else' )

		end

		it "only renders the first half of the contents if its attribute is true" do
			renderstate = Inversion::RenderState.new( :attribute => true )
			@tag.render( renderstate ).to_s.should == 'the body before else'
		end

		it "only renders the second half of the contents if its attribute is true" do
			renderstate = Inversion::RenderState.new( :attribute => false )
			@tag.render( renderstate ).to_s.should == 'the body after else'
		end

	end

	context "with a single 'elsif' and an 'else' clause" do

		before( :each ) do
			@tag = Inversion::Template::IfTag.new( 'attribute' )
			@tag << Inversion::Template::TextNode.new( 'the body before elsif' )
			@tag << Inversion::Template::ElsifTag.new( 'elsifattribute' )
			@tag << Inversion::Template::TextNode.new( 'the body after elsif' )
			@tag << Inversion::Template::ElseTag.new
			@tag << Inversion::Template::TextNode.new( 'the body after else' )
		end

		it "only renders the first third of the contents if its attribute is true" do
			renderstate = Inversion::RenderState.new( :attribute => true )
			@tag.render( renderstate ).to_s.should == 'the body before elsif'
		end

		it "only renders the second third of the contents if the attribute is false and the " +
		   "elsif's attribute is true" do
			renderstate = Inversion::RenderState.new( :attribute => false, :elsifattribute => true )
			@tag.render( renderstate ).to_s.should == 'the body after elsif'
		end

		it "only renders the last third of the contents if both the attribute and the elsif's " +
		   "attribute are false" do
			renderstate = Inversion::RenderState.new( :attribute => false, :elsifattribute => false )
			@tag.render( renderstate ).to_s.should == 'the body after else'
		end

	end


	context "with only a single 'elsif' clause" do

		before( :each ) do
			@tag = Inversion::Template::IfTag.new( 'attribute' )
			@tag << Inversion::Template::TextNode.new( 'the body before elsif' )
			@tag << Inversion::Template::ElsifTag.new( 'elsifattribute' )
			@tag << Inversion::Template::TextNode.new( 'the body after elsif' )
		end

		it "only renders the first half of the contents if its attribute is true" do
			renderstate = Inversion::RenderState.new( :attribute => true )
			@tag.render( renderstate ).to_s.should == 'the body before elsif'
		end

		it "only renders the second half of the contents if the attribute is false and the " +
		   "elsif's attribute is true" do
			renderstate = Inversion::RenderState.new( :attribute => false, :elsifattribute => true )
			@tag.render( renderstate ).to_s.should == 'the body after elsif'
		end

		it "doesn't render anything if both the attribute and the elsif's attribute are false" do
			renderstate = Inversion::RenderState.new( :attribute => false, :elsifattribute => false )
			@tag.render( renderstate ).to_s.should == ''
		end

	end


	context "with two 'elsif' clauses" do

		before( :each ) do
			@tag = Inversion::Template::IfTag.new( 'attribute' )
			@tag << Inversion::Template::TextNode.new( 'the body before elsif' )
			@tag << Inversion::Template::ElsifTag.new( 'elsifattribute' )
			@tag << Inversion::Template::TextNode.new( 'the body after elsif1' )
			@tag << Inversion::Template::ElsifTag.new( 'elsifattribute2' )
			@tag << Inversion::Template::TextNode.new( 'the body after elsif2' )
		end

		it "only renders the first third of the contents if its attribute is true" do
			renderstate = Inversion::RenderState.new( :attribute => true )
			@tag.render( renderstate ).to_s.should == 'the body before elsif'
		end

		it "only renders the second third of the contents if the attribute is false and the " +
		   "first elsif's attribute is true" do
			renderstate = Inversion::RenderState.new( :elsifattribute => true )
			@tag.render( renderstate ).to_s.should == 'the body after elsif1'
		end

		it "only renders the last third of the contents if both the attribute and the first elsif's " +
		   "attribute are false, but the second elsif's attribute is true" do
			renderstate = Inversion::RenderState.new( :elsifattribute2 => true )
			@tag.render( renderstate ).to_s.should == 'the body after elsif2'
		end

		it "doesn't render anything if all three attributes are false" do
			renderstate = Inversion::RenderState.new
			@tag.render( renderstate ).to_s.should == ''
		end

	end


	context "with two 'elsif' clauses and an 'else' clause" do

		before( :each ) do
			@tag = Inversion::Template::IfTag.new( 'attribute' )
			@tag << Inversion::Template::TextNode.new( 'the body before elsif' )
			@tag << Inversion::Template::ElsifTag.new( 'elsifattribute' )
			@tag << Inversion::Template::TextNode.new( 'the body after elsif1' )
			@tag << Inversion::Template::ElsifTag.new( 'elsifattribute2' )
			@tag << Inversion::Template::TextNode.new( 'the body after elsif2' )
			@tag << Inversion::Template::ElseTag.new
			@tag << Inversion::Template::TextNode.new( 'the body after else' )
		end

		it "only renders the first quarter of the contents if its attribute is true" do
			renderstate = Inversion::RenderState.new( :attribute => true )
			@tag.render( renderstate ).to_s.should == 'the body before elsif'
		end

		it "only renders the second quarter of the contents if the attribute is false and the " +
		   "first elsif's attribute is true" do
			renderstate = Inversion::RenderState.new( :elsifattribute => true )
			@tag.render( renderstate ).to_s.should == 'the body after elsif1'
		end

		it "only renders the third quarter of the contents if both the attribute and the first elsif's " +
		   "attribute are false, but the second elsif's attribute is true" do
			renderstate = Inversion::RenderState.new( :elsifattribute2 => true )
			@tag.render( renderstate ).to_s.should == 'the body after elsif2'
		end

		it "renders the last quarter of the contents if all three attributes are false" do
			renderstate = Inversion::RenderState.new
			@tag.render( renderstate ).to_s.should == 'the body after else'
		end

	end


end



