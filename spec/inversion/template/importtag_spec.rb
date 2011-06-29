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
require 'inversion/template/importtag'

describe Inversion::Template::ImportTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end

	it "can import a single attribute" do
		tag = Inversion::Template::ImportTag.new( 'txn ' )
		tag.attributes.should == [ :txn ]
	end

	it "can import multiple attributes" do
		tag = Inversion::Template::ImportTag.new( 'txn, applet' )
		tag.attributes.should == [ :txn, :applet ]
	end


	context "with a single attribute name" do

		before( :each ) do
			@subtemplate = Inversion::Template.new( '<?import foo ?><?attr foo ?>' )
		end

		it "copies the named value from the enclosing template" do
			outside = Inversion::Template.new( '<?attr foo ?><?attr subtemplate ?>' )
			outside.subtemplate = @subtemplate
			outside.foo = 'Froo'

			outside.render.should == 'FrooFroo'
		end

		it "doesn't override values set explicitly on the subtemplate" do
			outside = Inversion::Template.new( '<?attr foo ?><?attr subtemplate ?>' )
			outside.subtemplate = @subtemplate
			outside.foo = 'Froo'

			@subtemplate.foo = 'Frar'

			outside.render.should == 'FrooFrar'
		end

	end


	context "with multiple attribute names" do

		before( :each ) do
			source = '<?import foo, bar ?><?attr foo.capitalize ?>: ' +
				'<?attr bar.capitalize ?><?attr baz ?>'
			@subtemplate = Inversion::Template.new( source )
		end

		it "copies the named value from the enclosing template" do
			outside = Inversion::Template.new( '<?attr subtemplate ?>' )
			outside.subtemplate = @subtemplate
			outside.foo = 'mission'
			outside.bar = 'accomplished'

			outside.render.should == 'Mission: Accomplished'
		end

		it "doesn't override values set explicitly on the subtemplate" do
			outside = Inversion::Template.new( '<?attr subtemplate ?>' )
			outside.subtemplate = @subtemplate
			outside.foo = 'mission'
			outside.bar = 'accomplished'

			@subtemplate.bar = 'abandoned'

			outside.render.should == 'Mission: Abandoned'
		end

		it "only imports listed attributes" do
			outside = Inversion::Template.new( '<?attr subtemplate ?>' )
			outside.subtemplate = @subtemplate
			outside.foo = 'Attributes'
			outside.bar = 'Just This One'
			outside.baz = 'And Not This One'

			outside.render.should == 'Attributes: Just this one'
		end
	end

end


