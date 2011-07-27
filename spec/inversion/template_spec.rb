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

	it "renders the source as-is if there are no instructions" do
		Inversion::Template.new( "a template" ).render.should == 'a template'
	end

	it "renders when stringified" do
		Inversion::Template.new( "a template" ).to_s.should == 'a template'
	end

	it "untaints template content loaded from a file" do
		content = 'file contents'.taint
		IO.should_receive( :read ).with( '/tmp/hooowat' ).and_return( content )

		Inversion::Template.load( '/tmp/hooowat' ).source.should_not be_tainted()
	end

	it "calls before and after rendering hooks on all of its nodes when rendered" do
		node = double( "fake node" )
		parentstate = Inversion::RenderState.new( :foo => 'the merged stuff' )
		tmpl = Inversion::Template.new( '' )
		tmpl.node_tree << node

		node.should_receive( :before_rendering ).with( an_instance_of(Inversion::RenderState) )
		node.should_receive( :render ).with( an_instance_of(Inversion::RenderState) )
		node.should_receive( :after_rendering ).with( an_instance_of(Inversion::RenderState) )

		tmpl.render( parentstate )
	end


	it "passes the block it was rendered with to its RenderState" do
		node = double( "fake node", :before_rendering => nil, :after_rendering => nil )
		tmpl = Inversion::Template.new( '' )
		tmpl.node_tree << node

		renderblock = Proc.new {}
		node.should_receive( :render ).and_return do |renderstate|
			renderstate.block.should equal( renderblock )
		end

		tmpl.render( &renderblock )
	end

	it "can make an human-readable string version of itself suitable for debugging" do
		IO.should_receive( :read ).with( '/tmp/inspect.tmpl' ).and_return( '<?attr foo ?>' )
		tmpl = Inversion::Template.load( '/tmp/inspect.tmpl' )
		tmpl.inspect.should =~ /Inversion::Template/
		tmpl.inspect.should =~ %r{/tmp/inspect.tmpl}
		tmpl.inspect.should =~ /attributes/
		tmpl.inspect.should =~ /node_tree/
	end

	it "provides accessors for attributes that aren't identifiers in the template" do
		tmpl = Inversion::Template.new( '' )
		tmpl.foo = :bar
		tmpl.foo.should == :bar
	end


	context "without template paths set" do

		before( :each ) do
			Inversion::Template.config[:template_paths].clear
		end

		it "instances can be loaded from an absolute path" do
			IO.should_receive( :read ).with( '/tmp/hooowat' ).and_return( 'file contents' )
			Inversion::Template.load( '/tmp/hooowat' ).source.should == 'file contents'
		end

		it "instances can be loaded from a path relative to the current working directory" do
			tmplpath = Pathname.pwd + 'hooowat.tmpl'
			FileTest.should_receive( :exist? ).with( tmplpath.to_s ).and_return( true )
			IO.should_receive( :read ).with( tmplpath.to_s ).and_return( 'file contents' )
			Inversion::Template.load( 'hooowat.tmpl' ).source.should == 'file contents'
		end
	end


	context "with template paths set" do

		before( :each ) do
			Inversion::Template.config[:template_paths] = [ '/tmp', '/fun' ]
		end

		after( :each ) do
			Inversion::Template.config[:template_paths].clear
		end

		it "instances can be loaded from an absolute path" do
			FileTest.should_not_receive( :exist? )

			IO.should_receive( :read ).with( '/tmp/hooowat' ).and_return( 'file contents' )
			Inversion::Template.load( '/tmp/hooowat' ).source.should == 'file contents'
		end

		it "raises a runtime exception if unable to locate the template" do
			tmplpath = Pathname.pwd + 'sadmanhose.tmpl'

			FileTest.should_receive( :exist? ).with( '/tmp/sadmanhose.tmpl' ).and_return( false )
			FileTest.should_receive( :exist? ).with( '/fun/sadmanhose.tmpl' ).and_return( false )
			FileTest.should_receive( :exist? ).with( tmplpath.to_s ).and_return( false )

			expect {
				Inversion::Template.load( 'sadmanhose.tmpl' )
			}.to raise_error( RuntimeError, /unable to find template ".+" within configured paths/i )
		end

		it "loads template relative to directories in the template_paths" do
			FileTest.should_receive( :exist? ).with( '/tmp/hooowat.tmpl' ).and_return( false )
			FileTest.should_receive( :exist? ).with( '/fun/hooowat.tmpl' ).and_return( true )
			IO.should_receive( :read ).with( '/fun/hooowat.tmpl' ).and_return( 'file contents' )

			Inversion::Template.load( 'hooowat.tmpl' ).source.should == 'file contents'
		end

		it "falls back to loading the template relative to the current working directory" do
			tmplpath = Pathname.pwd + 'hooowat.tmpl'

			FileTest.should_receive( :exist? ).with( '/tmp/hooowat.tmpl' ).and_return( false )
			FileTest.should_receive( :exist? ).with( '/fun/hooowat.tmpl' ).and_return( false )
			FileTest.should_receive( :exist? ).with( tmplpath.to_s ).and_return( true )
			IO.should_receive( :read ).with( tmplpath.to_s ).and_return( 'file contents' )

			Inversion::Template.load( 'hooowat.tmpl' ).source.should == 'file contents'
		end
	end


	context "with an attribute PI" do

		let( :template ) { Inversion::Template.new("<h1><?attr foo ?></h1>") }


		it "has a reader for getting the attribute's value" do
			template.should respond_to( :foo )
		end

		it "has an accessor for setting the attribute's value" do
			template.should respond_to( :foo= )
		end

		it "renders scalar values set for the attribute" do
			template.foo = "a lion"
			template.render.should == "<h1>a lion</h1>"
		end

		it "renders an non-String value set for the attribute using #to_s" do
			template.foo = [ 'a lion', 'a little guy', 'a bad mousie', 'one birdy' ]
			template.render.should == %{<h1>a liona little guya bad mousieone birdy</h1>}
		end
	end


	context "with several attribute PIs" do

		let( :template ) { Inversion::Template.new("<h1><?attr foo ?> <?attr foo?> RUN!</h1>") }

		it "has a reader for getting the attribute's value" do
			template.should respond_to( :foo )
		end

		it "has an accessor for setting the attribute's value" do
			template.should respond_to( :foo= )
		end

		it "renders scalar values set for the attribute(s)" do
			template.foo = "lions!!"
			template.render.should == "<h1>lions!! lions!! RUN!</h1>"
		end
	end


	describe "Configurability support", :if => defined?( Configurability ) do

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
			  ignore_unknown_tags: false
			  debugging_comments: true
			  comment_start: "#"
			  comment_end: ""
			}.gsub(/^\t{3}/, '') )

			Inversion::Template.configure( config.templates )

			Inversion::Template.config[:ignore_unknown_tags].should be_false()
			Inversion::Template.config[:debugging_comments].should be_true()
			Inversion::Template.config[:comment_start].should == '#'
			Inversion::Template.config[:comment_end].should == ''

		end

	end


	describe "exception-handling:" do

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
			@tmpl.render.should == "Some stuff\nMore stuff"
		end

		it "can be configured to insert debugging comments for exceptions raised while rendering" do
			@tmpl.options[:on_render_error] = :comment
			@tmpl.render.should ==
				"Some stuff\n<!-- RuntimeError: Okay, here's an exception! -->More stuff"
		end

		it "can be configured to propagate exceptions raised while rendering" do
			@tmpl.options[:on_render_error] = :propagate
			expect {
				@tmpl.render
			}.to raise_exception( RuntimeError, /Okay, here's an exception!/ )
		end

	end


end

