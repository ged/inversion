#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/unlesstag'
require 'inversion/template/textnode'
require 'inversion/renderstate'

RSpec.describe Inversion::Template::UnlessTag do


	it "renders its contents if its attribute is false" do
		tag = Inversion::Template::UnlessTag.new( 'attribute' )
		tag << Inversion::Template::TextNode.new( 'the body' )

		renderstate = Inversion::RenderState.new( :attribute => false )
		tag.render( renderstate )
		expect( renderstate.to_s ).to eq( 'the body' )
	end

	it "renders its contents if its methodchain is false" do
		tag = Inversion::Template::UnlessTag.new( 'attribute.key?(:foo)' )
		tag << Inversion::Template::TextNode.new( 'the body' )

		renderstate = Inversion::RenderState.new( :attribute => {:bar => 1} )
		tag.render( renderstate )
		expect( renderstate.to_s ).to eq( 'the body' )
	end

	it "doesn't render its contents if its attribute is true" do
		tag = Inversion::Template::UnlessTag.new( 'attribute' )
		tag << Inversion::Template::TextNode.new( 'the body' )

		renderstate = Inversion::RenderState.new( :attribute => true )
		tag.render( renderstate )
		expect( renderstate.to_s ).to eq( '' )
	end

	it "doesn't render its contents if its methodchain is true" do
		tag = Inversion::Template::UnlessTag.new( 'attribute.key?(:foo)' )
		tag << Inversion::Template::TextNode.new( 'the body' )

		renderstate = Inversion::RenderState.new( :attribute => {:foo => 1} )
		tag.render( renderstate )
		expect( renderstate.to_s ).to eq( '' )
	end

	it "inverts its attribute with a ! operator" do
		template = Inversion::Template.new( <<-END_TEMPLATE )
		<?unless ! thing ?>Yep.<?else?>Nope.<?end?>
		END_TEMPLATE

		template.thing = false
		expect( template.render ).to include( "Nope." )
		template.thing = true
		expect( template.render ).to include( "Yep." )
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
			@tag.render( renderstate )
			expect( renderstate.to_s ).to eq( 'the body after else' )
		end

		it "only renders the first half of the contents if its attribute is false" do
			renderstate = Inversion::RenderState.new( :attribute => false )
			@tag.render( renderstate )
			expect( renderstate.to_s ).to eq( 'the body before else' )
		end

	end

end
