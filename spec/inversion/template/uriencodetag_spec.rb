#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/uriencodetag'

describe Inversion::Template::UriencodeTag do

	before( :each ) do
		@attribute_object = double( "template attribute" )
	end


	it "URI encodes the results of rendering" do
		template = Inversion::Template.new( 'this is<?uriencode foo.bar ?>' )
		template.foo = @attribute_object
		expect( @attribute_object ).to receive( :bar ).with( no_args() ).
			and_return( " 25% Sparta!" )

		expect( template.render ).to eq( "this is%2025%25%20Sparta%21" )
	end

	it "stringifies its content before encoding" do
		template = Inversion::Template.new( '<?uriencode foo.bar ?> bottles of beer on the wall' )
		template.foo = @attribute_object
		expect( @attribute_object ).to receive( :bar ).with( no_args() ).
			and_return( 99.999 )

		expect( template.render ).to eq( "99.999 bottles of beer on the wall" )
	end
end
