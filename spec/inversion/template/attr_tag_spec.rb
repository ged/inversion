#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'inversion/template/attr_tag'

describe Inversion::Template::AttrTag do

	it "knows what its own name is" do
		described_class.new( 'foo' ).name.should == 'foo'
	end

end


