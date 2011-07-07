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
require 'inversion/template/tag'

describe Inversion::Template::Tag do

	before( :all ) do
		setup_logging( :fatal )
		@real_derivatives = Inversion::Template::Tag.derivatives.dup
		@real_types = Inversion::Template::Tag.types.dup
	end

	before( :each ) do
		Inversion::Template::Tag.derivatives.clear
		Inversion::Template::Tag.types.clear
	end

	after( :all ) do
		Inversion::Template::Tag.instance_variable_set( :@derivatives, @real_derivatives )
		Inversion::Template::Tag.instance_variable_set( :@types, @real_types )
		reset_logging()
	end


	it "loads pluggable types via Rubygems" do
		Gem.stub( :find_files ).
			with( Inversion::Template::Tag::TAG_PLUGIN_PATTERN ).
			and_return([ 'inversion/template/zebratag.rb' ])
		Inversion::Template::Tag.should_receive( :require ).
			with( 'inversion/template/zebratag.rb' ).
			and_return {
				Class.new( Inversion::Template::Tag ) {
					def self::name; "ZebraTag"; end
				}
			}
		result = Inversion::Template::Tag.load_all
		result.should be_a( Hash )
		result.should have( 1 ).member
		result.should have_key( :zebra )
		result[:zebra].should be_a( Class )
		result[:zebra].should < Inversion::Template::Tag
	end

	it "doesn't include abstract tag types in its loading mechanism" do
		Gem.stub( :find_files ).
			with( Inversion::Template::Tag::TAG_PLUGIN_PATTERN ).
			and_return([ 'inversion/template/zebratag.rb' ])
		Inversion::Template::Tag.should_receive( :require ).
			with( 'inversion/template/zebratag.rb' ).
			and_return {
				Class.new( Inversion::Template::Tag ) {
					include Inversion::AbstractClass
					def self::name; "ZebraTag"; end
				}
			}
		result = Inversion::Template::Tag.load_all
		result.should be_a( Hash )
		result.should == {}
	end


	it "raises an exception if told to create a tag with an invalid name" do
		expect {
			Inversion::Template::Tag.create( '', "employee.severance_amount.nonzero? ?>" )
		}.to raise_error( ArgumentError, /invalid tag name/i )
	end

	describe "concrete subclass" do

		before( :each ) do
			@tagclass = Class.new( Inversion::Template::Tag ) do
				def self::name; "Inversion::Template::ConcreteTag"; end
			end
			@tag = @tagclass.new( "the body" )
		end


		it "can render itself as a comment for template debugging" do
			@tag.as_comment_body.should == %{Concrete "the body" at line ??, column ??}
		end

	end

end

