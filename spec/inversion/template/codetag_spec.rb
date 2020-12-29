#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/codetag'

RSpec.describe Inversion::Template::CodeTag do


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


		it "can explicitly declare pattern inheritence" do
			parentclass = Class.new( Inversion::Template::CodeTag ) do
				tag_pattern "$(ident)" do |tag, match|
					:foo
				end
			end

			subclass = Class.new( parentclass ) do
				inherit_tag_patterns
				tag_pattern "$(op) $(ident)" do |tag, match|
					:bar
				end
			end

			expect( subclass.tag_patterns.size ).to eq( 2 )
			expect( subclass.tag_patterns.first[0] ).
				to be_an_instance_of( Inversion::Template::CodeTag::TokenPattern )
			expect( subclass.tag_patterns.last[0] ).
				to be_an_instance_of( Inversion::Template::CodeTag::TokenPattern )
			expect( subclass.tag_patterns.first[1].call(:dummy, :king_dummy) ).to eq( :foo )
			expect( subclass.tag_patterns.last[1].call(:dummy, :king_dummy) ).to eq( :bar )
		end


		it "throws an error if trying to inherit patterns after they are declared" do
			parentclass = Class.new( Inversion::Template::CodeTag ) do
				tag_pattern "$(ident)" do |tag, match|
					:foo
				end
			end

			expect {
				Class.new( parentclass ) do
					tag_pattern "$(op) $(ident)" do |tag, match|
						:bar
					end
					inherit_tag_patterns
				end
			}.to raise_exception( ScriptError, /patterns already exist/i )
		end
	end
end
