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
require 'inversion/template/pptag'

describe Inversion::Template::PpTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end

	before( :each ) do
		@attribute_object = double( "template attribute" )
	end


	it "dumps the results of rendering" do
		template = Inversion::Template.
			new( 'It looks like: <tt><?pp foo.bar ?></tt>.', :escape_format => :none )
		template.foo = @attribute_object
		@attribute_object.should_receive( :bar ).with( no_args() ).
			and_return({ :a_complex => [:datastructure, :or, :something] })

		template.render.should == "It looks like: <tt>{:a_complex=>[:datastructure, :or, :something]}</tt>."
	end

	it "escapes as HTML if the format is set to :html" do
		template = Inversion::Template.
			new( 'It looks like: <tt><?pp foo.bar ?></tt>.', :escape_format => :html )
		template.foo = @attribute_object
		@attribute_object.should_receive( :bar ).with( no_args() ).
			and_return({ :a_complex => [:datastructure, :or, :something] })

		template.render.should == "It looks like: <tt>{:a_complex=&gt;[:datastructure, :or, :something]}</tt>."
	end
end
