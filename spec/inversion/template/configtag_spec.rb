#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/configtag'

describe Inversion::Template::ConfigTag do

	# <?config comment_start: /* ?>
	# <?config comment_end: */ ?>
	it "can contain a single configuration setting" do
		tag = Inversion::Template::ConfigTag.new( 'comment_start: /*' )
		expect( tag.options ).to eq({ :comment_start => '/*' })
	end

	# <?config
	#     on_render_error: propagate
	#     debugging_comments: true
	#     comment_start: /*
	#     comment_end: */
	# ?>
	it "can contain multiple configuration settings using a YAML document" do
		yaml = <<-YAML
            on_render_error: propagate
            debugging_comments: true
            comment_start: "/*"
            comment_end: "*/"
		YAML
		tag = Inversion::Template::ConfigTag.new( yaml )

		expect( tag.options ).to eq({
			:on_render_error    => 'propagate',
			:debugging_comments => true,
			:comment_start      => '/*',
			:comment_end        => '*/'
		})
	end

	# <?config { comment_start: "/*", comment_end: "*/" } ?>
	it "can contain multiple configuration settings using an inline hash" do
		tag = Inversion::Template::ConfigTag.new( '{ comment_start: "/*", comment_end: "*/" }' )
		expect( tag.options ).to eq({ :comment_start => '/*', :comment_end => '*/' })
	end

	it "renders invisibly" do
		tag = Inversion::Template::ConfigTag.new( 'comment_start: /*' )
		state = Inversion::RenderState.new

		expect( tag.render(state) ).to be_nil
	end

	it "raises an error on an empty body" do
		expect {
			Inversion::Template::ConfigTag.new( '' )
		}.to raise_error( Inversion::ParseError, /empty config settings/i )
	end


	it "can change the strictness of the parser as it's parsing the template" do
		source = <<-TEMPLATE
		<?hooooowhat ?>
		<?config ignore_unknown_tags: false ?>
		something
		<?what ?>
		something else
		TEMPLATE
		expect {
			Inversion::Template.new( source, :ignore_unknown_tags => true )
		}.to raise_error( Inversion::ParseError, /unknown tag "what"/i )
	end

	it "can turn on debugging comments in rendered output" do
		source = <<-TEMPLATE
		<?config debugging_comments: true ?>
		something
		<?if foo ?>Van!<?end if ?>
		something else
		TEMPLATE
		tmpl = Inversion::Template.new( source )

		expect( tmpl.render ).to include( "<!-- If: { template.foo } -->" )
	end

	it "propagates options to subtemplates during parsing" do
		source = <<-TEMPLATE
		<?config ignore_unknown_tags: false ?>
		<?include unknown-tag.tmpl ?>
		TEMPLATE
		expect {
			Inversion::Template.new( source, template_paths: %w[spec/data] )
		}.to raise_error( Inversion::ParseError, /unknown tag "unknown"/i )
	end

	it "propagates options to subtemplates during rendering" do
		source = <<-TEMPLATE
		<?config debugging_comments: true ?>
		<?attr subtemplate ?>
		TEMPLATE
		tmpl = Inversion::Template.new( source )
		tmpl.subtemplate = Inversion::Template.load( 'unknown-tag.tmpl', template_paths: %w[spec/data] )

		expect( tmpl.render ).to match( /commented out 1 nodes on line 3: some stuff/i )
	end

end



