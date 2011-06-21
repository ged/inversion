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
require 'inversion/template/escapetag'

describe Inversion::Template::EscapeTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end

	before( :each ) do
		@attribute_object = mock( "template attribute" )
	end


	it "defaults to escaping as HTML" do
		template = Inversion::Template.new( 'this is <?escape foo.bar ?>' )
		template.foo = @attribute_object
		@attribute_object.should_receive( :bar ).with( no_args() ).
			and_return( "<the good, the bad, & the ugly>" )

		template.render.should == "this is &lt;the good, the bad, &amp; the ugly&gt;"
	end

	it "raises an Inversion::OptionsError if the config specifies an unsupported format" do
		template = Inversion::Template.new( 'this is <?escape foo.bar ?>',
				:escape_format => :clowns, :on_render_error => :propagate )
		template.foo = @attribute_object
		@attribute_object.should_receive( :bar ).with( no_args() ).
			and_return( "<the good, the bad, & the ugly>" )

		expect { template.render }.to raise_error Inversion::OptionsError, /no such escape format/i
	end

	it "escapes as HTML if the format is set to :html" do
		template = Inversion::Template.new( 'this is <?escape foo.bar ?>', :escape_format => :html )
		template.foo = @attribute_object
		@attribute_object.should_receive( :bar ).with( no_args() ).
			and_return( "<the good, the bad, & the ugly>" )

		template.render.should == "this is &lt;the good, the bad, &amp; the ugly&gt;"
	end
end
