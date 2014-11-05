#!/usr/bin/env rspec -cfd -b
# encoding: utf-8
# vim: set noet nosta sw=4 ts=4 :

require_relative '../helpers'

require 'inversion/renderstate'
require 'inversion/template/attrtag'
require 'inversion/template/textnode'
require 'inversion/template/fragmenttag'
require 'inversion/template/subscribetag'
require 'inversion/template/publishtag'

describe Inversion::RenderState do


	it "provides access to the block it was constructed with if there was one" do
		block = Proc.new {}
		state = Inversion::RenderState.new( &block )
		expect( state.block ).to equal( block )
	end

	it "can evaluate code in the context of itself" do
		attributes = { :foot => "in mouth", :bear => "in woods" }
		state = Inversion::RenderState.new( attributes )
		expect( state.eval( "foot" ) ).to eq( 'in mouth' )
	end


	describe "overridable attributes" do

		it "copies its initial attributes" do
			attributes = { :foot => "in mouth", :bear => "in woods" }

			state = Inversion::RenderState.new( attributes )

			expect( state.scope.__locals__ ).to_not equal( attributes )
			expect( state.scope[:foot] ).to eq( "in mouth" )
			expect( state.scope[:foot] ).to_not equal( attributes[:foot] )
			expect( state.scope[:bear] ).to eq( "in woods" )
			expect( state.scope[:bear] ).to_not equal( attributes[:bear] )
		end

		it "preserves tainted status when copying its attributes" do
			attributes = { :danger => "in pants" }
			attributes[:danger].taint

			state = Inversion::RenderState.new( attributes )

			expect( state.scope[:danger] ).to be_tainted()
		end

		it "preserves singleton methods on attribute objects when copying" do
			obj = Object.new
			def obj.foo; "foo!"; end

			state = Inversion::RenderState.new( :foo => obj )

			expect( state.scope[:foo].singleton_methods.map( &:to_sym ) ).to include( :foo )
		end

		it "preserves frozen status when copying its attributes" do
			attributes = { :danger => "in pants" }
			attributes[:danger].freeze

			state = Inversion::RenderState.new( attributes )

			expect( state.scope[:danger] ).to be_frozen()
		end

		it "can override its attributes for the duration of a block" do
			attributes = { :foot => "in mouth", :bear => "in woods" }

			state = Inversion::RenderState.new( attributes )

			state.with_attributes( :foot => 'ball' ) do
				expect( state.foot ).to eq( 'ball' )
				expect( state.bear ).to eq( 'in woods' )
			end

			expect( state.scope[:foot] ).to eq( 'in mouth' )
		end


		it "restores the original attributes if the block raises an exception" do
			attributes = { :foot => "in mouth", :bear => "in woods" }

			state = Inversion::RenderState.new( attributes )

			expect {
				state.with_attributes( {} ) do
					raise "Charlie dooo!"
				end
			}.to raise_error()

			expect( state.scope[:foot] ).to eq( 'in mouth' )
		end


		it "raises an error if #with_attributes is called without a block" do
			expect {
				Inversion::RenderState.new.with_attributes( {} )
			}.to raise_error( LocalJumpError, /no block/i )
		end

		describe Inversion::RenderState::Scope do

			it "provides accessor methods for its attributes" do
				state = Inversion::RenderState.new( :bar => :the_attribute_value )
				expect( state.scope.bar ).to eq( :the_attribute_value )
			end

			it "doesn't error if an accessor for a non-existant attribute is called" do
				state = Inversion::RenderState.new( :bar => :the_attribute_value )
				expect( state.scope.foo ).to be_nil()
			end

		end

		it "can be merged with another RenderState" do
			state = Inversion::RenderState.new(
				{:bar => :the_bar_value},
				{:debugging_comments => false} )
			anotherstate = Inversion::RenderState.new(
				{:foo => :the_foo_value},
				{:debugging_comments => true, :on_render_error => :propagate} )

			thirdstate = state.merge( anotherstate )

			expect( thirdstate.attributes ).to eq({
				:bar => :the_bar_value,
				:foo => :the_foo_value
			})
			expect( thirdstate.options ).to include(
				:debugging_comments => true,
				:on_render_error => :propagate
			)
		end

	end


	describe "context-aware tag state" do

		before( :each ) do
			@renderstate = Inversion::RenderState.new
		end

		it "provides a mechanism for storing tag state for the current render" do
			expect( @renderstate.tag_data ).to be_a( Hash )
		end

		it "can override tag state for the duration of a block" do
			@renderstate.tag_data[ :montana ] = 'excellent fishing'
			@renderstate.tag_data[ :colorado ] = 'fine fishing'

			@renderstate.with_tag_data( :alaska => 'good fishing' ) do
				expect( @renderstate.tag_data[:alaska] ).to eq( 'good fishing' )
				@renderstate.tag_data[:alaska] = 'blueberry bear poop'
				@renderstate.tag_data[:colorado] = 'Boulder has hippies'
			end

			expect( @renderstate.tag_data ).to_not have_key( :alaska )
			expect( @renderstate.tag_data[:montana] ).to eq( 'excellent fishing' )
			expect( @renderstate.tag_data[:colorado] ).to eq( 'fine fishing' )
		end

	end


	describe "render destinations" do

		it "can override the render destination for the duration of a block" do
			state = Inversion::RenderState.new

			original_dest = state.destination
			newdest = []
			node = Inversion::Template::TextNode.new( "New!" )
			rval = state.with_destination( newdest ) do
				state << node
			end
			expect( rval ).to equal( newdest )

			expect( newdest.size ).to eq( 1 )
			expect( newdest ).to include( 'New!' )
			expect( state.destination ).to equal( original_dest )
		end

		it "restores the original destination if the block raises an exception" do
			state = Inversion::RenderState.new

			original_dest = state.destination

			expect {
				state.with_destination( [] ) do
					raise "New!"
				end
			}.to raise_error()

			expect( state.destination ).to equal( original_dest )
		end

		it "raises an error if #with_destination is called without a block" do
			expect {
				Inversion::RenderState.new.with_destination( [] )
			}.to raise_error( LocalJumpError, /no block/i )
		end

	end


	describe "debugging comments" do

		it "adds a debugging comment when appending a node if debugging comments are enabled" do
			node = Inversion::Template::AttrTag.new( 'foo' )
			state = Inversion::RenderState.new( {}, :debugging_comments => true )

			state << node

			expect( state.to_s ).to eq( '<!-- Attr: { template.foo } -->' )
		end

		it "doesn't add a debugging comment when appending a node if debugging comments are disabled" do
			node = Inversion::Template::AttrTag.new( 'foo' )
			state = Inversion::RenderState.new( {}, :debugging_comments => false )

			state << node

			expect( state.to_s ).to eq( '' )
		end

	end


	describe "error-handling" do

		it "ignores errors while rendering appended nodes in 'ignore' mode" do
			node  = Inversion::Template::AttrTag.new( 'boom.klang' )
			state = Inversion::RenderState.new( {}, :on_render_error => :ignore )

			state << node

			expect( state.to_s ).to eq( '' )
		end

		it "adds a comment for errors while rendering appended nodes in 'comment' mode" do
			node  = Inversion::Template::AttrTag.new( 'boom.klang' )
			state = Inversion::RenderState.new( {}, :on_render_error => :comment )

			state << node

			expect( state.to_s ).to eq( "<!-- NoMethodError: undefined method `klang' for nil:NilClass -->" )
		end

		it "includes a backtrace when rendering errors in 'comment' mode with 'debugging_comments' enabled" do
			node  = Inversion::Template::AttrTag.new( 'boom.klang' )
			state = Inversion::RenderState.new( {}, :on_render_error => :comment, :debugging_comments => true )

			state << node
			output = state.to_s

			expect( output ).to include( "<!-- NoMethodError: undefined method `klang' for nil:NilClass" )
			expect( output ).to include( "#{__FILE__}:#{__LINE__ - 4}" )
		end

		it "re-raises errors while rendering appended nodes in 'propagate' mode" do
			node  = Inversion::Template::AttrTag.new( 'boom.klang' )
			state = Inversion::RenderState.new( {}, :on_render_error => :propagate )

			expect {
				state << node
			}.to raise_error( NoMethodError, /undefined method/ )
		end

		it "calls the provided handler if an exception is raised while the error handler has been " +
		   "overridden" do
			handler    = Proc.new do |state, node, err|
				"Yum, I eat %p from %p! Tasting good!" % [err.class, node.class]
			end
			node       = Inversion::Template::AttrTag.new( 'boom.klang' )
			state      = Inversion::RenderState.new( {}, :on_render_error => :propagate )
			defhandler = state.errhandler

			expect {
				state.with_error_handler( handler ) do
					state << node
				end
			}.to_not raise_error()

			expect( state.to_s ).to match( /yum, i eat nomethoderror/i )
			expect( state.errhandler ).to equal( defhandler )
		end

		it "raises an exception if the error handler is set to something that doesn't respond to #call" do
			state = Inversion::RenderState.new
			expect {
				state.with_error_handler( :foo )
			}.to raise_error( ArgumentError, /doesn't respond_to #call/i )
		end

		it "re-raises errors while rendering appended nodes in 'propagate' mode" do
			node  = Inversion::Template::AttrTag.new( 'boom.klang' )
			state = Inversion::RenderState.new( {}, :on_render_error => :propagate )

			expect {
				state << node
			}.to raise_error( NoMethodError, /undefined method/ )
		end

	end


	describe "publish/subscribe:" do

		before( :each ) do
			@state = Inversion::RenderState.new
		end

		it "doesn't have any subscriptions by default" do
			expect( @state.subscriptions ).to eq( {} )
		end

		it "allows an object to subscribe to node publications" do
			subscriber = Object.new

			@state.subscribe( :the_key, subscriber )

			expect( @state.subscriptions.size ).to eq( 1 )
			expect( @state.subscriptions[:the_key] ).to eq( [subscriber] )
		end

	end


	describe "conditional rendering" do

		before( :each ) do
			@state = Inversion::RenderState.new
		end

		it "allows rendering to be explicitly enabled and disabled" do
			expect( @state.rendering_enabled? ).to be_truthy()
			@state.disable_rendering
			expect( @state.rendering_enabled? ).to be_falsey()
			@state.enable_rendering
			expect( @state.rendering_enabled? ).to be_truthy()
		end

		it "allows rendering to be toggled" do
			expect( @state.rendering_enabled? ).to be_truthy()
			@state.toggle_rendering
			expect( @state.rendering_enabled? ).to be_falsey()
			@state.toggle_rendering
			expect( @state.rendering_enabled? ).to be_truthy()
		end

		it "doesn't render nodes that are appended to it if rendering is disabled" do
			@state << Inversion::Template::TextNode.new( "before" )
			@state.disable_rendering
			@state << Inversion::Template::TextNode.new( "during" )
			@state.enable_rendering
			@state << Inversion::Template::TextNode.new( "after" )

			expect( @state.to_s ).to eq( 'beforeafter' )
		end

	end


	describe "render timing" do

		before( :each ) do
			@state = Inversion::RenderState.new
		end


		it "knows how many floating-point seconds have passed since it was created" do
			expect( @state.time_elapsed ).to be_a( Float )
		end

	end


	describe "encoding support" do

		it "transcodes attribute values if the template's encoding is set" do
			attributes = {
				good_doggie: "Стрелка".encode('koi8-u'),
				little:      "arrow".encode('us-ascii')
			}

			state = Inversion::RenderState.new( attributes, encoding: 'utf-8' )

			state << Inversion::Template::AttrTag.new( 'good_doggie' )
			state << Inversion::Template::AttrTag.new( 'little' )

			expect( state.to_s.encoding ).to be( Encoding::UTF_8 )
		end

		it "replaces characters with undefined conversions instead of raising an encoding error" do
			bogus = "this character doesn't translate: \xc3 "
			bogus.force_encoding( 'binary' )

			attributes = {
				bogus: bogus,
				okay:  "this stuff will transcode fine"
			}

			state = Inversion::RenderState.new( attributes, encoding: 'utf-8' )

			state << Inversion::Template::AttrTag.new( 'okay' )
			state << Inversion::Template::AttrTag.new( 'bogus' )

			expect( state.to_s.encoding ).to be( Encoding::UTF_8 )
		end

	end


	describe "fragments" do

		before( :each ) do
			@state = Inversion::RenderState.new
		end


		it "can be set to an Array of rendered nodes" do
			subscribe_node = Inversion::Template::SubscribeTag.new( 'brand' )
			@state << subscribe_node

			publish_node = Inversion::Template::PublishTag.new( 'brand' )
			publish_node << Inversion::Template::TextNode.new( 'Acme' )
			@state << publish_node

			@state.add_fragment( :title, "Welcome to the ", subscribe_node, " website!" )

			expect( @state.fragments ).to be_a( Hash )
			expect( @state.fragments[:title] ).to eq([ "Welcome to the ", subscribe_node, " website!" ])
		end


		it "can be returned as a rendered Hash" do
			subscribe_node = Inversion::Template::SubscribeTag.new( 'brand' )
			@state << subscribe_node

			publish_node = Inversion::Template::PublishTag.new( 'brand' )
			publish_node << Inversion::Template::TextNode.new( 'Acme' )
			@state << publish_node

			@state.add_fragment( :title, "Welcome to the ", subscribe_node, " website!" )

			expect( @state.rendered_fragments ).to be_a( Hash )
			expect( @state.rendered_fragments[:title] ).to eq( "Welcome to the Acme website!" )
		end


		it "acts like a default if an attribute isn't set" do
			node = Inversion::Template::FragmentTag.new( 'pork' )
			node << Inversion::Template::AttrTag.new( 'bool' )
			node << Inversion::Template::TextNode.new( ' please!' )

			@state.scope[ :bool ] = 'yes'
			@state << node
			@state << Inversion::Template::TextNode.new( '--> ' )
			@state << Inversion::Template::AttrTag.new( 'pork' )
			@state << Inversion::Template::TextNode.new( ' <--' )

			expect( @state.to_s ).to eq( '--> yes please! <--' )
		end


		it "don't override explicitly-set attributes" do
			node = Inversion::Template::FragmentTag.new( 'pork' )
			node << Inversion::Template::AttrTag.new( 'bool' )
			node << Inversion::Template::TextNode.new( ' please!' )

			@state.scope[ :pork ] = 'pie'
			@state << node
			@state << Inversion::Template::TextNode.new( '--> ' )
			@state << Inversion::Template::AttrTag.new( 'pork' )
			@state << Inversion::Template::TextNode.new( ' <--' )

			expect( @state.to_s ).to eq( '--> pie <--' )
		end

	end

end

