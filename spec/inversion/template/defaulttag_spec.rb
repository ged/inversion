#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/defaulttag'

describe Inversion::Template::DefaultTag do


	it "sets a template attribute to a default value" do
		tmpl = Inversion::Template.new( '<?default foo to 11883 ?><?attr foo ?>' )
		expect( tmpl.render ).to eq( '11883' )
	end

	it "doesn't override a value set on the template as an attribute" do
		tmpl = Inversion::Template.new( '<?default foo to 11883 ?><?attr foo ?>' )
		tmpl.foo = 'bar'
		expect( tmpl.render ).to eq( 'bar' )
	end

	it "can set a template attribute to the result of calling a methodchain" do
		tmpl = Inversion::Template.
			new( '<?default width to foo.length ?><?attr foo ?>:<?attr width ?>' )
		tmpl.foo = 'bar'
		expect( tmpl.render ).to eq( 'bar:3' )
	end

	it "can format the default value" do
		tmpl = Inversion::Template.
			new( '<?default width to "[%02d]" % [ foo.length ] ?><?attr foo ?>:<?attr width ?>' )
		tmpl.foo = 'bar'
		expect( tmpl.render ).to eq( 'bar:[03]' )
	end

	it "can render itself as a comment for template debugging" do
		tag = Inversion::Template::DefaultTag.new( 'width to foo.length' )
		expect( tag.as_comment_body ).to eq( "Default 'width': { template.foo.length }" )
	end

end


