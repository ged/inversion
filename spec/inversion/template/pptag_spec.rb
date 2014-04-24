#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/pptag'

describe Inversion::Template::PpTag do

	before( :each ) do
		@attribute_object = double( "template attribute" )
	end


	it "dumps the results of rendering" do
		template = Inversion::Template.
			new( 'It looks like: <tt><?pp foo.bar ?></tt>.', :escape_format => :none )
		template.foo = @attribute_object
		expect( @attribute_object ).to receive( :bar ).with( no_args ).
			and_return({ :a_complex => [:datastructure, :or, :something] })

		expect(
			template.render
		).to eq( "It looks like: <tt>{:a_complex=>[:datastructure, :or, :something]}</tt>." )
	end

	it "escapes as HTML if the format is set to :html" do
		template = Inversion::Template.
			new( 'It looks like: <tt><?pp foo.bar ?></tt>.', :escape_format => :html )
		template.foo = @attribute_object
		expect( @attribute_object ).to receive( :bar ).with( no_args() ).
			and_return({ :a_complex => [:datastructure, :or, :something] })

		expect(
			template.render
		).to eq( "It looks like: <tt>{:a_complex=&gt;[:datastructure, :or, :something]}</tt>." )
	end
end
