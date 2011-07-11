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
require 'inversion/template/uriencodetag'

describe Inversion::Template::UriencodeTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end

	before( :each ) do
		@attribute_object = mock( "template attribute" )
	end


	it "URI encodes the results of rendering" do
		template = Inversion::Template.new( 'this is<?uriencode foo.bar ?>' )
		template.foo = @attribute_object
		@attribute_object.should_receive( :bar ).with( no_args() ).
			and_return( " 25% Sparta!" )

		template.render.should == "this is%2025%25%20Sparta%21"
	end

	it "stringifies its content before encoding" do
		template = Inversion::Template.new( '<?uriencode foo.bar ?> bottles of beer on the wall' )
		template.foo = @attribute_object
		@attribute_object.should_receive( :bar ).with( no_args() ).
			and_return( 99.999 )

		template.render.should == "99.999 bottles of beer on the wall"
	end
end
