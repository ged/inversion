#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/attrtag'

describe Inversion::Template::AttrTag do

	describe "parsing" do

		it "can have a simple attribute name" do
			expect( described_class.new( 'foo' ).name ).to eq( :foo )
		end

		it "can have an attribute name and a format string" do
			tag = described_class.new( '"%0.2f" % foo' )
			expect( tag.name ).to eq( :foo )
			expect( tag.format ).to eq( '%0.2f' )
		end

		it "raises an exception with an unknown operator" do
			expect {
				described_class.new( '"%0.2f" + foo' )
			}.to raise_error( Inversion::ParseError, /expected/ )
		end

		it "raises an exception if it has more than one identifier" do
			expect {
				described_class.new( '"%0.2f" % [ foo, bar ]' )
			}.to raise_error( Inversion::ParseError, /expected/ )
		end

		it "supports simple <identifier>.<methodname> syntax" do
			tag = described_class.new( 'foo.bar' )

			expect( tag.name ).to eq( :foo )
			expect( tag.methodchain ).to eq( '.bar' )
		end

		it "supports index operator (<identifier>.methodname[ <arguments> ]) syntax" do
			tag = described_class.new( 'foo.bar[8]' )

			expect( tag.name ).to eq( :foo )
			expect( tag.methodchain ).to eq( '.bar[8]' )
		end

		it "supports index operator (<identifier>[ <arguments> ]) syntax" do
			tag = described_class.new( 'foo[8]' )

			expect( tag.name ).to eq( :foo )
			expect( tag.methodchain ).to eq( '[8]' )
		end

		it "supports <identifier>.<methodname>( <arguments> ) syntax" do
			tag = described_class.new( 'foo.bar( 8, :baz )' )

			expect( tag.name ).to eq( :foo )
			expect( tag.methodchain ).to eq( '.bar( 8, :baz )' )
		end

		it "can have a format with a methodchain" do
			tag = described_class.new( '"%0.02f" % foo.bar( 8 )' )

			expect( tag.name ).to eq( :foo )
			expect( tag.methodchain ).to eq( '.bar( 8 )' )
			expect( tag.format ).to eq( '%0.02f' )
		end
	end

	describe "rendering" do

		it "can render itself as a comment for template debugging" do
			tag = described_class.new( 'foo.bar( 8, :baz )' )
			expect( tag.as_comment_body ).to eq( "Attr: { template.foo.bar( 8, :baz ) }" )
		end

		context "without a format" do

			before( :each ) do
				@tag = described_class.new( 'foo' )
			end

			it "renders as the stringified contents of the template attribute with the same name" do
				state = Inversion::RenderState.new( :foo => %w[floppy the turtle] )
				expect( @tag.render( state ) ).to eq( ["floppy", "the", "turtle"] )
			end

			it "doesn't error if the attribute isn't set on the template" do
				state = Inversion::RenderState.new( :foo => nil )
				expect( @tag.render( state ) ).to eq( nil )
			end

			it "returns false when the rendered value is false" do
				state = Inversion::RenderState.new( :foo => false )
				expect( @tag.render( state ) ).to equal( false )
			end

			it "can render itself as a comment for template debugging" do
				expect( @tag.as_comment_body ).to eq( 'Attr: { template.foo }' )
			end

		end

		context "with a format" do

			before( :each ) do
				@tag = described_class.new( 'foo' )
				@tag.format = "%0.2f"
			end

			it "renders as the formatted contents of the template attribute with the same name" do
				state = Inversion::RenderState.new( :foo => Math::PI )
				expect( @tag.render( state ) ).to eq( '3.14' )
			end

			it "doesn't error if the attribute isn't set on the template" do
				state = Inversion::RenderState.new( :foo => nil )
				expect( @tag.render(state) ).to eq( nil )
			end

			it "can render itself as a comment for template debugging" do
				expect( @tag.as_comment_body ).to eq( 'Attr: { template.foo } with format: "%0.2f"' )
			end

		end

		context "with a methodchain" do

			before( :each ) do
				@attribute_object = double( "template attribute" )
			end

			it "renders a single method call with no arguments" do
				template = Inversion::Template.new( 'this is <?attr foo.bar ?>' )
				template.foo = @attribute_object
				expect( @attribute_object ).to receive( :bar ).with( no_args() ).and_return( "the result" )

				expect( template.render ).to eq( "this is the result" )
			end

			it "renders a single method call with one argument" do
				template = Inversion::Template.new( 'this is <?attr foo.bar(8) ?>' )
				template.foo = @attribute_object
				expect( @attribute_object ).to receive( :bar ).with( 8 ).and_return( "the result" )

				expect( template.render ).to eq( "this is the result" )
			end

			it "renders a call with a single index operator" do
				template = Inversion::Template.new( 'lines end with <?attr config[:line_ending] ?>' )
				template.config = { :line_ending => 'newline' }

				expect( template.render ).to eq( "lines end with newline" )
			end

			it "renders a single method call with multiple arguments" do
				template = Inversion::Template.new( 'this is <?attr foo.bar(8, :woo) ?>' )
				template.foo = @attribute_object
				expect( @attribute_object ).to receive( :bar ).with( 8, :woo ).and_return( "the result" )

				expect( template.render ).to eq( "this is the result" )
			end

			it "renders multiple method calls with no arguments" do
				additional_object = double( 'additional template attribute' )
				template = Inversion::Template.new( 'this is <?attr foo.bar.baz ?>' )
				template.foo = @attribute_object
				expect( template.foo ).to receive( :bar ).and_return( additional_object )
				expect( additional_object ).to receive( :baz ).with( no_args() ).and_return( "the result" )

				expect( template.render ).to eq( "this is the result" )
			end

			it "renders multiple method calls with arguments" do
				additional_object = double( 'additional template attribute' )
				template = Inversion::Template.new( 'this is <?attr foo.bar( 8 ).baz( :woo ) ?>' )
				template.foo = @attribute_object
				expect( template.foo ).to receive( :bar ).with( 8 ).and_return( additional_object )
				expect( additional_object ).to receive( :baz ).with( :woo ).and_return( "the result" )

				expect( template.render ).to eq( "this is the result" )
			end

			it "renders method calls with template attribute arguments" do
				template = Inversion::Template.new( 'this is <?attr foo.bar( baz ) ?>' )
				foo = double( "foo attribute object" )

				template.foo = foo
				template.baz = 18
				expect( foo ).to receive( :bar ).with( 18 ).and_return( "the result of calling bar" )

				expect( template.render ).to eq( "this is the result of calling bar" )
			end
		end

	end

end


