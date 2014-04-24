#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/codetag'

describe Inversion::Template::CodeTag do


	it "is an abstract class" do
		expect( Inversion::Template::Tag ).to be < Inversion::AbstractClass
	end


	describe "subclasses" do

		it "can declare a format for tags using a declarative" do
			subclass = Class.new( Inversion::Template::CodeTag ) do
				tag_pattern "$(ident)" do |tag, match|
					:foo
				end
			end

			expect( subclass.tag_patterns.size ).to eq( 1 )
			expect( subclass.tag_patterns.first[0] ).
				to be_an_instance_of( Inversion::Template::CodeTag::TokenPattern )
			expect( subclass.tag_patterns.first[1].call(:dummy, :king_dummy) ).to eq( :foo )
		end

	end

end
