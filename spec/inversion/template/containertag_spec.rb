#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/containertag'

describe Inversion::Template::ContainerTag do

	context "instances of including classes" do

		before( :each ) do
			@including_class = Class.new( Inversion::Template::Tag ) do
				include Inversion::Template::ContainerTag
			end
			@tag = @including_class.new( 'a body' )
		end

		it "are container tags" do
			expect( @tag ).to be_a_container()
		end

		it "contain a subnodes array" do
			expect( @tag.subnodes ).to be_an( Array )
		end

		it "can have other nodes appended to them" do
			other_node = Inversion::Template::TextNode.new( "foom" )
			@tag << other_node
			expect( @tag.subnodes ).to include( other_node )
		end

	end
end



