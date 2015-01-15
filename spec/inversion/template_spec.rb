#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../helpers'

require 'stringio'

require 'inversion/template'

describe Inversion::Template do

	before( :all ) do
		@default_template_path = Inversion::Template.template_paths
		Inversion::Template::Tag.load_all
	end

	after( :all ) do
		Inversion::Template.template_paths = @default_template_path
	end


	context "created from a simple string" do

		let( :template ) { described_class.new("a template") }

		it "can be loaded from a String" do
			expect( template.source ).to eq( 'a template' )
		end

		it "renders the source as-is if there are no instructions" do
			expect( template.render ).to eq( 'a template' )
		end

		it "renders when stringified" do
			expect( template.to_s ).to eq( 'a template' )
		end

	end


	it "calls before and after rendering hooks on all of its nodes when rendered" do
		node = double( "fake node" )
		parentstate = Inversion::RenderState.new( :foo => 'the merged stuff' )
		tmpl = described_class.new( '' )
		tmpl.node_tree << node

		expect( node ).to receive( :before_rendering ).with( an_instance_of(Inversion::RenderState) )
		expect( node ).to receive( :render ).with( an_instance_of(Inversion::RenderState) )
		expect( node ).to receive( :after_rendering ).with( an_instance_of(Inversion::RenderState) )

		tmpl.render( parentstate )
	end


	it "passes the block it was rendered with to its RenderState" do
		node = double( "fake node", :before_rendering => nil, :after_rendering => nil )
		tmpl = described_class.new( '' )
		tmpl.node_tree << node

		renderblock = Proc.new {}
		expect( node ).to receive( :render ) do |renderstate|
			expect( renderstate.block ).to equal( renderblock )
		end

		tmpl.render( &renderblock )
	end

	it "carries its global configuration to the parser" do
		begin
			orig_config = described_class.config
			described_class.configure( :ignore_unknown_tags => false )

			expect {
				described_class.new( '<?rumple an unknown tag ?>' )
			}.to raise_error( Inversion::ParseError, /unknown tag/i )
		ensure
			described_class.config = orig_config
		end
	end

	it "carries its global configuration to per-template options" do
		begin
			orig_config = described_class.config
			described_class.configure( :stat_delay => 300 )

			template = described_class.new( 'hi!' )
			expect( template.options[ :stat_delay ] ).to eq( 300 )

			template = described_class.new( 'hi!', :stat_delay => 600 )
			expect( template.options[ :stat_delay ] ).to eq( 600 )
		ensure
			described_class.config = orig_config
		end
	end


	it "can make an human-readable string version of itself suitable for debugging" do
		expect( IO ).to receive( :read ).with( '/tmp/inspect.tmpl' ).and_return( '<?attr foo ?>' )
		tmpl = described_class.load( '/tmp/inspect.tmpl' )
		expect( tmpl.inspect ).to match( /#{Regexp.escape(described_class.name)}/ )
		expect( tmpl.inspect ).to match( %r{/tmp/inspect.tmpl} )
		expect( tmpl.inspect ).to match( /attributes/ )
		expect( tmpl.inspect ).to_not match( /node_tree/ )
	end

	it "includes the node tree in the inspected object if debugging is enabled" do
		begin
			debuglevel = $DEBUG
			$DEBUG = true

			tmpl = described_class.new( '<?attr something ?>' )
			expect( tmpl.inspect ).to match( /node_tree/ )
		ensure
			$DEBUG = debuglevel
		end
	end

	it "provides accessors for attributes that aren't identifiers in the template" do
		tmpl = described_class.new( '' )
		tmpl.foo = :bar
		expect( tmpl.foo ).to eq( :bar )
	end

	it "can pass an encoding option to IO.open through the template constructor" do
		content = 'some stuff'.encode( 'utf-8' )
		expect( IO ).to receive( :read ).with( '/a/utf8/template.tmpl', encoding: 'utf-8' ).and_return( content )
		template = described_class.load( '/a/utf8/template.tmpl', encoding: 'utf-8' )

		expect( template.render.encoding ).to eq( Encoding::UTF_8 )
	end


	it "can be extended at runtime via an extension module" do
		extension_mod = Module.new do
			def some_extension_stuff
				return :extension_stuff
			end
		end

		described_class.add_extensions( extension_mod )

		expect( described_class.new('a template').some_extension_stuff ).to eq( :extension_stuff )
	end


	it "can be extended at runtime with class methods via a ClassMethods submodule" do
		extension_mod = Module.new do
			module ClassMethods
				def some_class_extension_stuff; :class_extension_stuff; end
			end
		end

		described_class.add_extensions( extension_mod )

		expect( described_class.some_class_extension_stuff ).to eq( :class_extension_stuff )
	end


	it "can override methods at runtime with a PrependedMethods submodule" do
		extension_mod = Module.new do
			def a_method; :original_a_method; end

			module PrependedMethods
				def a_method; :extension_a_method; end
			end
		end

		described_class.add_extensions( extension_mod )

		expect( described_class.new('a template').a_method ).to eq( :extension_a_method )
	end


	context "loaded from a file" do

		before( :each ) do
			@timestamp = Time.now
			content = 'file contents'.taint
			allow( IO ).to receive( :read ).with( '/tmp/hooowat' ).and_return( content )
			@template = described_class.load( '/tmp/hooowat' )
		end


		it "untaints template content loaded from a file" do
			expect( @template.source ).to_not be_tainted()
		end

		it "can be reloaded" do
			newcontent = 'changed file contents'.taint
			expect( IO ).to receive( :read ).with( '/tmp/hooowat' ).and_return( newcontent )
			@template.reload
			expect( @template.source ).to eq( newcontent )
		end

		context "that hasn't changed since it was loaded" do

			before( :each ) do
				allow( @template.source_file ).to receive( :mtime ).and_return( @timestamp )
			end

			it "knows that it hasn't changed" do
				expect( @template ).to_not be_changed()
			end

			context "with a stat delay" do

				before( :each ) do
					@template.options[ :stat_delay ] = 30
				end

				it "returns unchanged if the delay time hasn't expired" do
					@template.instance_variable_set( :@last_checked, @timestamp )
					expect( @template ).to_not be_changed()
				end

				it "returns unchanged if the delay time has expired" do
					expect( @template.source_file ).to receive( :mtime ).and_return( @timestamp - 30 )
					@template.instance_variable_set( :@last_checked, @timestamp - 30 )
					expect( @template ).to_not be_changed()
				end
			end
		end

		context "that has changed since it was loaded" do

			before( :each ) do
				allow( @template.source_file ).to receive( :mtime ).and_return( @timestamp + 1 )
			end

			it "knows that is has changed" do
				expect( @template ).to be_changed()
			end

			context "with a stat delay" do

				before( :each ) do
					@template.options[ :stat_delay ] = 30
				end

				it "returns unchanged if the delay time hasn't expired" do
					@template.instance_variable_set( :@last_checked, @timestamp )
					expect( @template ).to_not be_changed()
				end

				it "returns changed if the delay time has expired" do
					@template.instance_variable_set( :@last_checked, @timestamp - 60 )
					expect( @template ).to be_changed()
				end
			end
		end
	end


	context "loaded from a String" do

		before( :each ) do
			@template = described_class.new( 'some stuff' )
		end

		it "never says it has changed" do
			expect( @template ).to_not be_changed()
		end

		it "raises an exception if reloaded" do
			expect {
				@template.reload
			}.to raise_error( Inversion::Error, /not loaded from a file/i )
		end

	end



	context "without template paths set" do

		before( :each ) do
			described_class.template_paths.clear
		end

		it "instances can be loaded from an absolute path" do
			expect( IO ).to receive( :read ).with( '/tmp/hooowat' ).and_return( 'file contents' )
			expect( described_class.load( '/tmp/hooowat' ).source ).to eq( 'file contents' )
		end

		it "instances can be loaded from a path relative to the current working directory" do
			tmplpath = Pathname.pwd + 'hooowat.tmpl'
			expect( FileTest ).to receive( :exist? ).with( tmplpath.to_s ).and_return( true )
			expect( IO ).to receive( :read ).with( tmplpath.to_s ).and_return( 'file contents' )
			expect( described_class.load( 'hooowat.tmpl' ).source ).to eq( 'file contents' )
		end

		it "instances can be loaded from a path provided via options" do
			expect( FileTest ).to receive( :exist? ).with( '/tmp/hooowat' ).and_return( true )
			expect( IO ).to receive( :read ).with( '/tmp/hooowat' ).and_return( 'file contents' )
			expect(
				described_class.load( 'hooowat', template_paths: %w[/tmp] ).source
			).to eq( 'file contents' )
		end

	end


	context "with template paths set" do

		before( :each ) do
			described_class.template_paths = [ '/tmp', '/fun' ]
		end

		after( :each ) do
			described_class.template_paths.clear
		end

		it "instances can be loaded from an absolute path" do
			expect( FileTest ).to_not receive( :exist? )

			expect( IO ).to receive( :read ).with( '/tmp/hooowat' ).and_return( 'file contents' )
			expect( described_class.load( '/tmp/hooowat' ).source ).to eq( 'file contents' )
		end

		it "raises a runtime exception if unable to locate the template" do
			tmplpath = Pathname.pwd + 'sadmanhose.tmpl'

			expect( FileTest ).to receive( :exist? ).with( '/tmp/sadmanhose.tmpl' ).and_return( false )
			expect( FileTest ).to receive( :exist? ).with( '/fun/sadmanhose.tmpl' ).and_return( false )
			expect( FileTest ).to receive( :exist? ).with( tmplpath.to_s ).and_return( false )

			expect {
				described_class.load( 'sadmanhose.tmpl' )
			}.to raise_error( RuntimeError, /unable to find template ".+" within configured paths/i )
		end

		it "loads template relative to directories in the template_paths" do
			expect( FileTest ).to receive( :exist? ).with( '/tmp/hooowat.tmpl' ).and_return( false )
			expect( FileTest ).to receive( :exist? ).with( '/fun/hooowat.tmpl' ).and_return( true )
			expect( IO ).to receive( :read ).with( '/fun/hooowat.tmpl' ).and_return( 'file contents' )

			expect( described_class.load( 'hooowat.tmpl' ).source ).to eq( 'file contents' )
		end

		it "falls back to loading the template relative to the current working directory" do
			tmplpath = Pathname.pwd + 'hooowat.tmpl'

			expect( FileTest ).to receive( :exist? ).with( '/tmp/hooowat.tmpl' ).and_return( false )
			expect( FileTest ).to receive( :exist? ).with( '/fun/hooowat.tmpl' ).and_return( false )
			expect( FileTest ).to receive( :exist? ).with( tmplpath.to_s ).and_return( true )
			expect( IO ).to receive( :read ).with( tmplpath.to_s ).and_return( 'file contents' )

			expect( described_class.load( 'hooowat.tmpl' ).source ).to eq( 'file contents' )
		end
	end


	context "with an attribute PI" do

		let( :template ) { described_class.new("<h1><?attr foo ?></h1>") }


		it "has a reader for getting the attribute's value" do
			expect( template ).to respond_to( :foo )
		end

		it "has an accessor for setting the attribute's value" do
			expect( template ).to respond_to( :foo= )
		end

		it "renders scalar values set for the attribute" do
			template.foo = "a lion"
			expect( template.render ).to eq( "<h1>a lion</h1>" )
		end

		it "renders an non-String value set for the attribute using #to_s" do
			template.foo = [ 'a lion', 'a little guy', 'a bad mousie', 'one birdy' ]
			expect( template.render ).to eq( %{<h1>a liona little guya bad mousieone birdy</h1>} )
		end
	end


	context "with several attribute PIs" do

		let( :template ) { described_class.new("<h1><?attr foo ?> <?attr foo?> RUN!</h1>") }

		it "has a reader for getting the attribute's value" do
			expect( template ).to respond_to( :foo )
		end

		it "has an accessor for setting the attribute's value" do
			expect( template ).to respond_to( :foo= )
		end

		it "renders scalar values set for the attribute(s)" do
			template.foo = "lions!!"
			expect( template.render ).to eq( "<h1>lions!! lions!! RUN!</h1>" )
		end
	end


	describe "Configurability support", :if => defined?( Configurability ) do

		after( :each ) do
			described_class.config = described_class::DEFAULT_CONFIG
		end

		it "is included in the list of configurable objects" do
			expect( Configurability.configurable_objects ).to include( described_class )
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

			described_class.configure( config.templates )

			expect( described_class.config[:ignore_unknown_tags] ).to be_falsey()
			expect( described_class.config[:debugging_comments] ).to be_truthy()
			expect( described_class.config[:comment_start] ).to eq( '#' )
			expect( described_class.config[:comment_end] ).to eq( '' )

		end

	end


	describe "exception-handling:" do

		before( :each ) do
			@source = "Some stuff\n<?call obj.raise_error ?>\nMore stuff"
			@tmpl = described_class.new( @source )

			@obj = Object.new
			def @obj.raise_error
				raise "Okay, here's an exception!"
			end

			@tmpl.obj = @obj
		end

		it "can be configured to completely ignore exceptions raised while rendering" do
			@tmpl.options[:on_render_error] = :ignore
			expect( @tmpl.render ).to eq( "Some stuff\nMore stuff" )
		end

		it "can be configured to insert debugging comments for exceptions raised while rendering" do
			@tmpl.options[:on_render_error] = :comment
			expect(
				@tmpl.render
			).to eq( "Some stuff\n<!-- RuntimeError: Okay, here's an exception! -->More stuff" )
		end

		it "can be configured to propagate exceptions raised while rendering" do
			@tmpl.options[:on_render_error] = :propagate
			expect {
				@tmpl.render
			}.to raise_error( RuntimeError, /Okay, here's an exception!/ )
		end

	end


	describe "with fragment tags" do

		before( :each ) do
			@template = Inversion::Template.new <<-TMPL
			<?default bool to 'yes' ?>
			<?fragment pork ?>wooo<?end ?>
			<?fragment beef ?><?attr bool ?> please<?end ?>
			<?attr beef ?>
			TMPL
		end

		it "doesn't have any fragments before it's been rendered" do
			expect( @template.fragments ).to be_empty
		end

		it "has a fragment for each tag after it's been rendered" do
			@template.render

			expect( @template.fragments ).to be_a( Hash )
			expect( @template.fragments ).to include( :pork, :beef )
			expect( @template.fragments.size ).to eq( 2 )
			expect( @template.fragments[:pork] ).to eq( 'wooo' )
			expect( @template.fragments[:beef] ).to eq( 'yes please' )
		end

		it "clears previous fragments when rendered a second time" do
			@template.render
			expect( @template.fragments[:beef] ).to eq( 'yes please' )

			@template.bool = 'no'
			@template.render
			expect( @template.fragments[:beef] ).to eq( 'no please' )
		end

	end

end

