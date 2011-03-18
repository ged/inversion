#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'inversion/template/tag'

describe Inversion::Template::Tag do

	it "loads pluggable types via Rubygems" do
		Gem.stub( :find_files ).
			with( Inversion::Template::Tag::TAG_PLUGIN_PATTERN ).
			and_return([ 'inversion/template/zebra_tag.rb' ])
		Inversion::Template::Tag.should_receive( :require ).
			with( 'inversion/template/zebra_tag.rb' ).
			and_return {
				Class.new( Inversion::Template::Tag )
			}
		result = Inversion::Template::Tag.load_all
		result.should be_a( Hash )
		result.should have( 1 ).member
		result.should have_key( :zebra )
		result[:zebra].should be_a( Class )
		result[:zebra].should < Inversion::Template::Tag
	end

end

