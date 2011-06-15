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

describe Inversion::RenderState do

	before( :all ) do
		setup_logging( :fatal )
	end

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


	it "preserves frozen status when copying its attributes" do
		attributes = { :danger => "in pants" }
		attributes[:danger].freeze

		state = Inversion::RenderState.new( attributes )

		state.attributes[:danger].should be_frozen()
	end


	it "preserves singleton methods on attribute objects when copying" do
		obj = Object.new
		def obj.foo; "foo!"; end

		state = Inversion::RenderState.new( :foo => obj )

		state.attributes[:foo].singleton_methods.should include( :foo )
	end


	it "can evaluate code in the context of itself" do
		attributes = { :foot => "in mouth", :bear => "in woods" }

		state = Inversion::RenderState.new( attributes )

		state.eval( "foot" ).should == 'in mouth'
	end

	it "can override its attributes for the duration of a block" do
		attributes = { :foot => "in mouth", :bear => "in woods" }

		state = Inversion::RenderState.new( attributes )

		state.with_attributes( :foot => 'ball' ) do
			state.foot.should == 'ball'
			state.bear.should == 'in woods'
		end
	end

	it "raises an error if #with_attributes is called without a block" do
		expect {
			Inversion::RenderState.new.with_attributes( {} )
		}.to raise_error( LocalJumpError, /no block/i )
	end
end

