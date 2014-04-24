#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template'
require 'inversion/template/textnode'
require 'inversion/template/subscribetag'

describe Inversion::Template::SubscribeTag do


	it "raises a parse error if the key isn't a simple attribute" do
		expect {
			Inversion::Template::SubscribeTag.new( 'a.non-identifier' )
		}.to raise_error( Inversion::ParseError, /malformed subscribe/i )
	end

	it "renders the nodes published by an immediate subtemplate with the same key" do
		template = Inversion::Template.new( '--<?subscribe stylesheets ?>--<?attr subtemplate ?>' )
		subtemplate = Inversion::Template.new( '<?publish stylesheets ?>a style<?end?>(subtemplate)' )

		template.subtemplate = subtemplate

		expect( template.render ).to eq( '--a style--(subtemplate)' )
	end

	it "renders nodes published by an immediate subtemplate that's rendered before it" do
		template = Inversion::Template.new( '--<?attr subtemplate ?>--<?subscribe stylesheets ?>' )
		subtemplate = Inversion::Template.new( '<?publish stylesheets ?>a style<?end?>(subtemplate)' )

		template.subtemplate = subtemplate

		expect( template.render ).to eq( '--(subtemplate)--a style' )
	end

	it "doesn't render anything if there are no publications with its key" do
		template = Inversion::Template.new( '--<?subscribe nostylesheets ?>--<?attr subtemplate ?>' )
		subtemplate = Inversion::Template.new( '<?publish stylesheets ?>a style<?end?>(subtemplate)' )

		template.subtemplate = subtemplate

		expect( template.render ).to eq( '----(subtemplate)' )
	end

	it "renders a default value if one is supplied" do
		template = Inversion::Template.new( "<?subscribe not_here || default value! ?>" )
		expect( template.render ).to eq( "default value!" )
	end

	it "doesn't retain published nodes across renders" do
		template = Inversion::Template.new( '--<?subscribe stylesheets ?>--<?attr subtemplate ?>' )
		subtemplate = Inversion::Template.new( '<?publish stylesheets ?>a style<?end?>(subtemplate)' )

		template.subtemplate = subtemplate

		expect( template.render ).to eq( '--a style--(subtemplate)' )
		expect( template.render ).to eq( '--a style--(subtemplate)' )
	end

end


