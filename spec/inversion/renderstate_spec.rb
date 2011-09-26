#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent.parent
	libdir  = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s )  unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'

require 'spec/lib/helpers'
require 'inversion/renderstate'
require 'inversion/template/attrtag'
require 'inversion/template/textnode'

describe Inversion::RenderState do

	before( :all ) do
		setup_logging( :fatal )
	end

	it "provides access to the block it was constructed with if there was one" do
		block = Proc.new {}
		state = Inversion::RenderState.new( &block )
		state.block.should equal( block )
	end

	it "can evaluate code in the context of itself" do
		attributes = { :foot => "in mouth", :bear => "in woods" }

		state = Inversion::RenderState.new( attributes )

		state.eval( "foot" ).should == 'in mouth'
	end


	describe "overridable attributes" do

		it "copies its initial attributes" do
			attributes = { :foot => "in mouth", :bear => "in woods" }

			state = Inversion::RenderState.new( attributes )

			state.attributes.should_not equal( attributes )
			state.attributes[:foot].should == "in mouth"
			state.attributes[:foot].should_not equal( attributes[:foot] )
			state.attributes[:bear].should == "in woods"
			state.attributes[:bear].should_not equal( attributes[:bear] )
		end

		it "preserves tainted status when copying its attributes" do
			attributes = { :danger => "in pants" }
			attributes[:danger].taint

			state = Inversion::RenderState.new( attributes )

			state.attributes[:danger].should be_tainted()
		end

		it "preserves singleton methods on attribute objects when copying" do
			obj = Object.new
			def obj.foo; "foo!"; end

			state = Inversion::RenderState.new( :foo => obj )

			state.attributes[:foo].singleton_methods.map( &:to_sym ).should include( :foo )
		end

		it "preserves frozen status when copying its attributes" do
			attributes = { :danger => "in pants" }
			attributes[:danger].freeze

			state = Inversion::RenderState.new( attributes )

			state.attributes[:danger].should be_frozen()
		end

		it "can override its attributes for the duration of a block" do
			attributes = { :foot => "in mouth", :bear => "in woods" }

			state = Inversion::RenderState.new( attributes )

			state.with_attributes( :foot => 'ball' ) do
				state.foot.should == 'ball'
				state.bear.should == 'in woods'
			end

			state.attributes[:foot].should == 'in mouth'
		end


		it "restores the original attributes if the block raises an exception" do
			attributes = { :foot => "in mouth", :bear => "in woods" }

			state = Inversion::RenderState.new( attributes )

			expect {
				state.with_attributes( {} ) do
					raise "Charlie dooo!"
				end
			}.to raise_error()

			state.attributes[:foot].should == 'in mouth'
		end


		it "raises an error if #with_attributes is called without a block" do
			expect {
				Inversion::RenderState.new.with_attributes( {} )
			}.to raise_error( LocalJumpError, /no block/i )
		end

		it "provides accessor methods for its attributes" do
			state = Inversion::RenderState.new( :bar => :the_attribute_value )
			state.bar.should == :the_attribute_value
		end

		it "doesn't error if an accessor for a non-existant attribute is called" do
			state = Inversion::RenderState.new( :bar => :the_attribute_value )
			state.foo.should be_nil()
		end

		it "can be merged with another RenderState" do
			state = Inversion::RenderState.new(
				{:bar => :the_bar_value},
				{:debugging_comments => false} )
			anotherstate = Inversion::RenderState.new(
				{:foo => :the_foo_value},
				{:debugging_comments => true, :on_render_error => :propagate} )

			thirdstate = state.merge( anotherstate )

			thirdstate.attributes.should == {
				:bar => :the_bar_value,
				:foo => :the_foo_value
			}
			thirdstate.options.should include(
				:debugging_comments => true,
				:on_render_error => :propagate
			)
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
			rval.should equal( newdest )

			newdest.should have( 1 ).member
			newdest.should include( 'New!' )
			state.destination.should equal( original_dest )
		end

		it "restores the original destination if the block raises an exception" do
			state = Inversion::RenderState.new

			original_dest = state.destination

			expect {
				state.with_destination( [] ) do
					raise "New!"
				end
			}.to raise_error()

			state.destination.should equal( original_dest )
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

			state.to_s.should == '<!-- Attr: { template.foo } -->'
		end

		it "doesn't add a debugging comment when appending a node if debugging comments are disabled" do
			node = Inversion::Template::AttrTag.new( 'foo' )
			state = Inversion::RenderState.new( {}, :debugging_comments => false )

			state << node

			state.to_s.should == ''
		end

	end


	describe "error-handling" do

		it "ignores errors while rendering appended nodes in 'ignore' mode" do
			node  = Inversion::Template::AttrTag.new( 'boom.klang' )
			state = Inversion::RenderState.new( {}, :on_render_error => :ignore )

			state << node

			state.to_s.should == ''
		end

		it "adds a comment for errors while rendering appended nodes in 'comment' mode" do
			node  = Inversion::Template::AttrTag.new( 'boom.klang' )
			state = Inversion::RenderState.new( {}, :on_render_error => :comment )

			state << node

			state.to_s.should == "<!-- NoMethodError: undefined method `klang' for nil:NilClass -->"
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

			state.to_s.should =~ /yum, i eat nomethoderror/i
			state.errhandler.should equal( defhandler )
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
			@state.subscriptions.should == {}
		end

		it "allows an object to subscribe to node publications" do
			subscriber = Object.new

			@state.subscribe( :the_key, subscriber )

			@state.subscriptions.should have( 1 ).member
			@state.subscriptions[ :the_key ].should == [ subscriber ]
		end

	end

end

