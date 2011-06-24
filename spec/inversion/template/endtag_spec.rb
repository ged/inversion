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
require 'inversion/template/textnode'
require 'inversion/template/endtag'
require 'inversion/renderstate'

describe Inversion::Template::EndTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	before( :each ) do
		@tag = Inversion::Template::EndTag.new
	end

	after( :all ) do
		reset_logging()
	end


	it "doesn't render as anything" do
		renderstate = Inversion::RenderState.new
		@tag.render( renderstate ).should be_nil()
	end

	it "can render itself as a comment body that outputs what it closes" do
		# <?for i IN foo ?>...<?end ?>
		template = Inversion::Template.
			new( "<?for foo in bar ?>Chunkers<?end ?>", :debugging_comments => true )
		template.bar = [ :an_item ]
		template.render.should =~ /<!-- End of For: { foo IN template.bar } -->/
	end


end



