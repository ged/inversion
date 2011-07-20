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
require 'inversion/template/defaulttag'

describe Inversion::Template::DefaultTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	it "sets a template attribute to a default value" do
		tmpl = Inversion::Template.new( '<?default foo to 11883 ?><?attr foo ?>' )
		tmpl.render.should == '11883'
	end

	it "doesn't override a value set on the template as an attribute" do
		tmpl = Inversion::Template.new( '<?default foo to 11883 ?><?attr foo ?>' )
		tmpl.foo = 'bar'
		tmpl.render.should == 'bar'
	end

	it "can set a template attribute to the result of calling a methodchain" do
		tmpl = Inversion::Template.
			new( '<?default width to foo.length ?><?attr foo ?>:<?attr width ?>' )
		tmpl.foo = 'bar'
		tmpl.render.should == 'bar:3'
	end

	it "can format the default value" do
		tmpl = Inversion::Template.
			new( '<?default width to "[%02d]" % [ foo.length ] ?><?attr foo ?>:<?attr width ?>' )
		tmpl.foo = 'bar'
		tmpl.render.should == 'bar:[03]'
	end

	it "can render itself as a comment for template debugging" do
		tag = Inversion::Template::DefaultTag.new( 'width to foo.length' )
		tag.as_comment_body.should == "Default 'width': { template.foo.length }"
	end

end


