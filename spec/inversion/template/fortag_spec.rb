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
require 'inversion/template/fortag'
require 'inversion/template/attrtag'
require 'inversion/template/textnode'
require 'inversion/renderstate'

describe Inversion::Template::ForTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	it "can iterate over single items of a collection attribute" do
		tag = Inversion::Template::ForTag.new( 'foo in bar' )

		tag.block_args.should == [ :foo ]
		tag.enumerator.should == 'bar'
	end

	it "renders each of its subnodes for each iteration, replacing its " +
	   "block arguments with the yielded values" do
		render_scope = Inversion::RenderState.new( :bar => %w[monkey goat] )

		# <?for foo in bar ?>
		tag = Inversion::Template::ForTag.new( 'foo in bar' )

		# [<?attr foo?>]
		tag << Inversion::Template::TextNode.new( '[' )
		tag << Inversion::Template::AttrTag.new( 'foo' )
		tag << Inversion::Template::TextNode.new( ']' )

		tag.render( render_scope ).should == "[monkey][goat]"
	end

	it "raises a ParseError if a keyword other than 'in' is used" do
		expect {
			Inversion::Template::ForTag.new( 'foo begin bar' )
		}.to raise_exception( Inversion::ParseError, /invalid/i )
	end

	context "multidimensional collections" do

		it "can be expanded into multiple block arguments" do
			tag = Inversion::Template::ForTag.new( 'splip, splorp in splap' )

			tag.block_args.should == [ :splip, :splorp ]
			tag.enumerator.should == 'splap'
		end


		it "can be expanded into multiple block arguments (sans spaces)" do
			tag = Inversion::Template::ForTag.new( 'splip,splorp,sploop in splap' )

			tag.block_args.should == [ :splip, :splorp, :sploop ]
			tag.enumerator.should == 'splap'
		end
	end
end



