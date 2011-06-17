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
require 'inversion/template/configtag'

describe Inversion::Template::ConfigTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	# <?config comment_start: /* ?>
	# <?config comment_end: */ ?>
	it "can contain a single configuration setting" do
		tag = Inversion::Template::ConfigTag.new( 'comment_start: /*' )
		tag.options.should == { :comment_start => '/*' }
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
            comment_start: /*
            comment_end: */
		YAML
		tag = Inversion::Template::ConfigTag.new( yaml )
		tag.options.should == {
			:on_render_error    => 'propagate',
			:debugging_comments => true,
			:comment_start      => '/*',
			:comment_end        => '*/'
		}
	end

	# <?config { comment_start: "/*", comment_end: "*/" } ?>
	it "can contain multiple configuration settings using an inline hash" do
		tag = Inversion::Template::ConfigTag.new( '{ comment_start: "/*", comment_end: "*/" }' )
		tag.options.should == { :comment_start => '/*', :comment_end => '*/' }
	end

	it "renders invisibly" do
		tag = Inversion::Template::ConfigTag.new( 'comment_start: /*' )
		tag.render.should == ''
	end

	it "raises an error on an empty body" do
		expect {
			Inversion::Template::ConfigTag.new( '' )
		}.to raise_exception( Inversion::ParseError, /empty config settings/i )
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
		}.to raise_exception( Inversion::ParseError, /unknown tag "what"/i )
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
		}.to raise_exception( Inversion::ParseError, /unknown tag "what"/i )
	end

end



