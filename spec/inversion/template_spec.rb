#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent.parent
	libdir  = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s )  unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'stringio'

require 'spec/lib/helpers'
require 'inversion/template'

describe Inversion::Template do

	before( :all ) do
		setup_logging( :fatal )
	end

	it "can be loaded from a String" do
		Inversion::Template.new( "a template" ).source.should == 'a template'
	end

	it "can be loaded from an IO" do
		io = StringIO.new( 'a template' )
		Inversion::Template.new( io ).source.should == 'a template'
	end

	it "can be loaded from a file" do
		io = StringIO.new( 'file contents' )
		File.should_receive( :open ).with( '/tmp/hooowat', 'r' ).and_yield( io )
		Inversion::Template.load( '/tmp/hooowat' ).source.should == 'file contents'
	end

	it "renders the source as-is if there are no instructions" do
		Inversion::Template.new( "a template" ).render.should == 'a template'
	end


	context "exception-handling" do

		before( :each ) do
			@source = "Some stuff\n<?call obj.raise_exception ?>\nMore stuff"
			@tmpl = Inversion::Template.new( @source )

			@obj = Object.new
			def @obj.raise_exception
				raise "Okay, here's an exception!"
			end

			@tmpl.obj = @obj
		end

		it "can be configured to completely ignore exceptions raised while rendering" do
			@tmpl.options[:on_render_error] = :ignore
			@tmpl.render.should == "Some stuff\n\nMore stuff"
		end

		it "can be configured to insert debugging comments for exceptions raised while rendering" do
			@tmpl.options[:on_render_error] = :comment
			@tmpl.render.bytes.to_a.should == 
				"Some stuff\n<!-- RuntimeError: Okay, here's an exception! -->\nMore stuff".bytes.to_a
		end

		it "can be configured to propagate exceptions raised while rendering" do
			@tmpl.options[:on_render_error] = :propagate
			expect {
				@tmpl.render
			}.to raise_exception( RuntimeError, /Okay, here's an exception!/ )
		end

	end


	context "with an attribute PI" do

		let( :template ) { Inversion::Template.new("<h1><?attr foo ?></h1>") }


		it "has a reader for getting the tag's value" do
			template.should respond_to( :foo )
		end

		it "has an accessor for setting the tag's value" do
			template.should respond_to( :foo= )
		end

		it "renders scalar values set for the tag" do
			template.foo = "a lion"
			template.render.should == "<h1>a lion</h1>"
		end

		it "renders an non-String value set for the tag using #to_s" do
			template.foo = [ 'a lion', 'a little guy', 'a bad mousie', 'one birdy' ]
			template.render.should == %{<h1>["a lion", "a little guy", "a bad mousie", "one birdy"]</h1>}
		end
	end


	context "with numerous attribute PIs" do

		let( :template ) { Inversion::Template.new("<h1><?attr foo ?> <?attr foo?> RUN!</h1>") }

		it "has a reader for getting the tag's value" do
			template.should respond_to( :foo )
		end

		it "has an accessor for setting the tag's value" do
			template.should respond_to( :foo= )
		end

		it "renders scalar values set for the tag(s)" do
			template.foo = "lions!!"
			template.render.should == "<h1>lions!! lions!! RUN!</h1>"
		end
	end


	context "if Configurability is installed", :if => defined?( Configurability ) do

		after( :each ) do
			Inversion::Template.config = Inversion::Template::DEFAULT_CONFIG
		end

		it "is included in the list of configurable objects" do
			Configurability.configurable_objects.should include( Inversion::Template )
		end

		it "can be configured using a Configurability::Config object" do
			config = Configurability::Config.new( %{
			---
			templates:
			  raise_on_unknown: true
			  debugging_comments: true
			  comment_start: "#"
			  comment_end: ""
			}.gsub(/^\t{3}/, '') )

			Inversion::Template.configure( config.templates )

			Inversion::Template.config[:raise_on_unknown].should be_true()
			Inversion::Template.config[:debugging_comments].should be_true()
			Inversion::Template.config[:comment_start].should == '#'
			Inversion::Template.config[:comment_end].should == ''

		end

	end

end

