#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/escapetag'

describe Inversion::Template::EscapeTag do

	before( :each ) do
		@attribute_object = double( "template attribute" )
	end


	it "defaults to escaping as HTML" do
		template = Inversion::Template.new( 'this is <?escape foo.bar ?>' )
		template.foo = @attribute_object
		expect( @attribute_object ).to receive( :bar ).with( no_args() ).
			and_return( "<the good, the bad, & the ugly>" )

		expect( template.render ).to eq( "this is &lt;the good, the bad, &amp; the ugly&gt;" )
	end

	it "raises an Inversion::OptionsError if the config specifies an unsupported format" do
		template = Inversion::Template.new( 'this is <?escape foo.bar ?>',
				:escape_format => :clowns, :on_render_error => :propagate )
		template.foo = @attribute_object
		expect( @attribute_object ).to receive( :bar ).with( no_args() ).
			and_return( "<the good, the bad, & the ugly>" )

		expect {
			template.render
		}.to raise_error( Inversion::OptionsError, /no such escape format/i )
	end

	it "escapes as HTML if the format is set to :html" do
		template = Inversion::Template.new( 'this is <?escape foo.bar ?>', :escape_format => :html )
		template.foo = @attribute_object
		expect( @attribute_object ).to receive( :bar ).with( no_args() ).
			and_return( "<the good, the bad, & the ugly>" )

		expect( template.render ).to eq( "this is &lt;the good, the bad, &amp; the ugly&gt;" )
	end
end
