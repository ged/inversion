#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/importtag'

describe Inversion::Template::ImportTag do

	it "can import a single attribute" do
		tag = Inversion::Template::ImportTag.new( 'txn ' )
		expect( tag.attributes ).to eq( [ :txn ] )
	end

	it "can import multiple attributes" do
		tag = Inversion::Template::ImportTag.new( 'txn, applet' )
		expect( tag.attributes ).to eq( [ :txn, :applet ] )
	end


	context "with a single attribute name" do

		before( :each ) do
			@subtemplate = Inversion::Template.new( '<?import foo ?><?attr foo ?>' )
		end

		it "copies the named value from the enclosing template" do
			outside = Inversion::Template.new( '<?attr foo ?><?attr subtemplate ?>' )
			outside.subtemplate = @subtemplate
			outside.foo = 'Froo'

			expect( outside.render ).to eq( 'FrooFroo' )
		end

		it "doesn't override values set explicitly on the subtemplate" do
			outside = Inversion::Template.new( '<?attr foo ?><?attr subtemplate ?>' )
			outside.subtemplate = @subtemplate
			outside.foo = 'Froo'

			@subtemplate.foo = 'Frar'

			expect( outside.render ).to eq( 'FrooFrar' )
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

			expect( outside.render ).to eq( 'Mission: Accomplished' )
		end

		it "doesn't override values set explicitly on the subtemplate" do
			outside = Inversion::Template.new( '<?attr subtemplate ?>' )
			outside.subtemplate = @subtemplate
			outside.foo = 'mission'
			outside.bar = 'accomplished'

			@subtemplate.bar = 'abandoned'

			expect( outside.render ).to eq( 'Mission: Abandoned' )
		end

		it "only imports listed attributes" do
			outside = Inversion::Template.new( '<?attr subtemplate ?>' )
			outside.subtemplate = @subtemplate
			outside.foo = 'Attributes'
			outside.bar = 'Just This One'
			outside.baz = 'And Not This One'

			expect( outside.render ).to eq( 'Attributes: Just this one' )
		end
	end

end


