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
require 'inversion/template/codetag'

describe Inversion::Template::CodeTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	it "is an abstract class" do
		Inversion::Template::Tag.should < Inversion::AbstractClass
	end


	describe "subclasses" do

		it "can declare a format for tags using a declarative" do
			subclass = Class.new( Inversion::Template::CodeTag ) do
				tag_pattern "$(ident)" do |tag, match|
					:foo
				end

			end

			subclass.tag_patterns.should have( 1 ).member
			subclass.tag_patterns.first[0].
				should be_an_instance_of( Inversion::Template::CodeTag::TokenPattern )
			subclass.tag_patterns.first[1].call( :dummy, :king_dummy ).should == :foo
		end

	end

end
