#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/tag'

describe Inversion::Template::Tag do

	before( :all ) do
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
	end


	it "loads pluggable types via Rubygems" do
		pluginfile = '/usr/lib/ruby/gems/1.8/gems/inversion-extra-1.0.8/lib/inversion/template/zebratag.rb'
		expect( Gem ).to receive( :find_files ).
			with( Inversion::Template::Tag::TAG_PLUGIN_PATTERN ).
			and_return([ pluginfile ])
		expect( Inversion::Template::Tag ).to receive( :require ) do |filename|
			expect( filename ).to eq( 'inversion/template/zebratag' )
			Class.new( Inversion::Template::Tag ) do
				def self::name; "Inversion::Template::ZebraTag"; end
			end
		end
		result = Inversion::Template::Tag.load_all
		expect( result ).to be_a( Hash )
		expect( result.size ).to eq( 1 )
		expect( result ).to have_key( :zebra )
		expect( result[:zebra] ).to be_a( Class )
		expect( result[:zebra] ).to be < Inversion::Template::Tag
	end

	it "doesn't include abstract tag types in its loading mechanism" do
		pluginfile = '/usr/lib/ruby/gems/1.8/gems/inversion-extra-1.0.8/lib/inversion/template/zebratag.rb'
		expect( Gem ).to receive( :find_files ).
			with( Inversion::Template::Tag::TAG_PLUGIN_PATTERN ).
			and_return([ pluginfile ])
		expect( Inversion::Template::Tag ).to receive( :require ) do |filename|
			expect( filename ).to eq( 'inversion/template/zebratag' )
			Class.new( Inversion::Template::Tag ) do
				include Inversion::AbstractClass
				def self::name; "Inversion::Template::ZebraTag"; end
			end
		end
		result = Inversion::Template::Tag.load_all
		expect( result ).to be_a( Hash )
		expect( result ).to eq( {} )
	end


	it "raises an exception if told to create a tag with an invalid name" do
		expect {
			Inversion::Template::Tag.create( '', "employee.severance_amount.nonzero? ?>" )
		}.to raise_error( ArgumentError, /invalid tag name/i )
	end


	it "includes support for snake_case tag names" do
		pluginfile = '/usr/lib/ruby/gems/1.8/gems/inversion-extra-1.0.8/lib/inversion/template/two_hump_camel_tag.rb'
		expect( Gem ).to receive( :find_files ).
			with( Inversion::Template::Tag::TAG_PLUGIN_PATTERN ).
			and_return([ pluginfile ])
		expect( Inversion::Template::Tag ).to receive( :require ) do |filename|
			expect( filename ).to eq( 'inversion/template/two_hump_camel_tag' )
			Class.new( Inversion::Template::Tag ) do
				def self::name; "Inversion::Template::TwoHumpCamelTag"; end
			end
		end
		result = Inversion::Template::Tag.load_all
		expect( result ).to be_a( Hash )
		expect( result.size ).to eq( 2 )
		expect( result ).to have_key( :twohumpcamel )
		expect( result ).to have_key( :two_hump_camel )
		expect( result[:two_hump_camel] ).to be_a( Class )
		expect( result[:two_hump_camel] ).to be < Inversion::Template::Tag
	end


	describe "concrete subclass" do

		before( :each ) do
			@tagclass = Class.new( Inversion::Template::Tag ) do
				def self::name; "Inversion::Template::ConcreteTag"; end
			end
			@tag = @tagclass.new( "the body" )
		end


		it "can render itself as a comment for template debugging" do
			expect( @tag.as_comment_body ).to eq( %{Concrete "the body" at line ??, column ??} )
		end

	end

end

