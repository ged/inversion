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
require 'inversion/template/containertag'

describe Inversion::Template::ContainerTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end

	context "instances of including classes" do

		before( :each ) do
			@including_class = Class.new( Inversion::Template::Tag ) do
				include Inversion::Template::ContainerTag
			end
			@tag = @including_class.new( 'a body' )
		end

		it "are container tags" do
			@tag.should be_a_container()
		end

		it "contain a subnodes array" do
			@tag.subnodes.should be_an( Array )
		end

		it "can have other nodes appended to them" do
			other_node = Inversion::Template::TextNode.new( "foom" )
			@tag << other_node
			@tag.subnodes.should include( other_node )
		end

	end
end



