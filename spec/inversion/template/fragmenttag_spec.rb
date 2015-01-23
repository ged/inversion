#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/fragmenttag'
require 'inversion/template/attrtag'
require 'inversion/template/textnode'
require 'inversion/renderstate'

describe Inversion::Template::FragmentTag do

	it "raises a parse error if the body isn't a simple attribute" do
		expect {
			Inversion::Template::FragmentTag.new( 'something-else' )
		}.to raise_error( Inversion::ParseError, /malformed key/i )
	end


	it "doesn't render its contents in the template it's declared in" do
		expect(
			Inversion::Template.new( "<?fragment foo ?>Fatty BoomBoom<?end ?>" ).render
		).to eq( '' )
	end


	it "sets the attribute on the template object when rendered" do
		tmpl = Inversion::Template.new(
			'<?fragment subject ?>Order #<?attr order_number ?><?end?>-- <?attr subject ?> --'
		)

		tmpl.order_number = '2121bf8c4'
		output = tmpl.render

		expect( output ).to eq( "-- Order #2121bf8c4 --" )
		expect( tmpl.fragments[:subject] ).to eq( "Order #2121bf8c4" )
	end


	it "propagates fragments to the outermost template when they're nested" do
		inner_tmpl = Inversion::Template.new(
			'<?fragment subject ?>Order #<?attr order_number ?><?end?>-- <?attr subject ?> --'
		)
		outer_tmpl = Inversion::Template.new(
			'<?attr content ?>'
		)

		inner_tmpl.order_number = '2121bf8c4'
		outer_tmpl.content = inner_tmpl
		output = outer_tmpl.render

		expect( output ).to eq( "-- Order #2121bf8c4 --" )
		expect( outer_tmpl.fragments[:subject] ).to eq( "Order #2121bf8c4" )
	end

end

