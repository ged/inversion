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
require 'inversion/template'
require 'inversion/template/textnode'
require 'inversion/template/subscribetag'

describe Inversion::Template::SubscribeTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	it "raises a parse error if the key isn't a simple attribute" do
		expect {
			Inversion::Template::SubscribeTag.new( 'a.non-identifier' )
		}.should raise_exception( Inversion::ParseError, /malformed subscribe/i )
	end

	it "renders the nodes published by an immediate subtemplate with the same key" do
		template = Inversion::Template.new( '--<?subscribe stylesheets ?>--<?attr subtemplate ?>' )
		subtemplate = Inversion::Template.new( '<?publish stylesheets ?>a style<?end?>(subtemplate)' )

		template.subtemplate = subtemplate

		template.render.should == '--a style--(subtemplate)'
	end

	it "doesn't render anything if there are no publications with its key" do
		template = Inversion::Template.new( '--<?subscribe nostylesheets ?>--<?attr subtemplate ?>' )
		subtemplate = Inversion::Template.new( '<?publish stylesheets ?>a style<?end?>(subtemplate)' )

		template.subtemplate = subtemplate

		template.render.should == '----(subtemplate)'
	end

	it "renders a default value if one is supplied" do
		template = Inversion::Template.new( "<?subscribe not_here || default value! ?>" )
		template.render.should == "default value!"
	end
end


