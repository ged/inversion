#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../helpers'

require 'inversion/parser'

describe Inversion::Parser do

	before( :all ) do
		Inversion::Template::Tag.load_all
	end

	before( :each ) do
		@template = double( "An Inversion::Template" )
	end

	it "parses a string with no PIs as a single text node" do
		result = Inversion::Parser.new( @template ).parse( "render unto Caesar" )

		expect( result.size ).to eq( 1 )
		expect( result.first ).to be_a( Inversion::Template::TextNode )
		expect( result.first.body ).to eq( 'render unto Caesar' )
	end

	it "parses an empty string as a empty tree" do
		result = Inversion::Parser.new( @template ).parse( "" )
		expect( result ).to be_empty
	end

	it "raises a ParseError on mismatched tag brackets" do
		expect {
			Inversion::Parser.new( @template ).parse( '[?foo bar ?>' )
		}.to raise_error( Inversion::ParseError, /mismatched start and end brackets/i )
	end

	it "parses a string with a single 'attr' tag as a single AttrTag node" do
		result = Inversion::Parser.new( @template ).parse( "<?attr foo ?>" )

		expect( result.size ).to eq( 1 )
		expect( result.first ).to be_a( Inversion::Template::AttrTag )
		expect( result.first.body ).to eq( 'foo' )
	end

	it "parses a single 'attr' tag surrounded by plain text" do
		result = Inversion::Parser.new( @template ).parse( "beginning<?attr foo ?>end" )

		expect( result.size ).to eq( 3 )
		expect( result[0] ).to be_a( Inversion::Template::TextNode )
		expect( result[1] ).to be_a( Inversion::Template::AttrTag )
		expect( result[1].body ).to eq( 'foo' )
		expect( result[2] ).to be_a( Inversion::Template::TextNode )
	end

	it "ignores unknown tags by default" do
		result = Inversion::Parser.new( @template ).parse( "Text <?hoooowhat ?>" )

		expect( result.size ).to eq( 2 )
		expect( result[0] ).to be_a( Inversion::Template::TextNode )
		expect( result[1] ).to be_a( Inversion::Template::TextNode )
		expect( result[1].body ).to eq( '<?hoooowhat ?>' )
	end

	it "can raise exceptions on unknown tags" do
		expect {
			Inversion::Parser.new( @template, :ignore_unknown_tags => false ).
				parse( "Text <?hoooowhat ?>" )
		}.to raise_error( Inversion::ParseError, /unknown tag/i )
	end

	it "can raise exceptions on unclosed (nested) tags" do
		expect {
			Inversion::Parser.new( @template ).parse( "Text <?attr something <?attr something_else ?>" )
		}.to raise_error( Inversion::ParseError, /unclosed or nested tag/i )
	end

	it "can raise exceptions on unclosed (eof) tags" do
		expect {
			Inversion::Parser.new( @template ).parse( "Text <?hoooowhat" )
		}.to raise_error( Inversion::ParseError, /unclosed tag/i )
	end


	describe Inversion::Parser::State do

		before( :each ) do
			@state = Inversion::Parser::State.new( @template )
		end

		it "returns the node tree if it's well-formed" do
			open_tag = Inversion::Template::ForTag.new( 'foo in bar' )
			end_tag  = Inversion::Template::EndTag.new( 'for' )

			@state << open_tag << end_tag

			expect( @state.tree ).to eq( [ open_tag, end_tag ] )
		end

		it "knows it is well-formed if there are no open tags" do
			@state << Inversion::Template::ForTag.new( 'foo in bar' )
			expect( @state ).to_not be_well_formed

			@state << Inversion::Template::ForTag.new( 'foo in bar' )
			expect( @state ).to_not be_well_formed

			@state << Inversion::Template::EndTag.new( 'for' )
			expect( @state ).to_not be_well_formed

			@state << Inversion::Template::EndTag.new( 'for' )
			expect( @state ).to be_well_formed
		end

		it "can pop a container tag off of the current context" do
			container = Inversion::Template::ForTag.new( 'foo in bar' )
			@state << container
			expect( @state.pop ).to eq( container )
		end

		it "calls the #after_appending hook of container nodes when they're popped" do
			container = double( "container tag", :before_appending => false, :is_container? => true )
			@state << container

			expect( container ).to receive( :after_appending ).with( @state )
			@state.pop
		end

		it "raises an error when popping if there is no container tag" do
			expect {
				@state.pop
			}.to raise_error( Inversion::ParseError, /unbalanced end: no open tag/i )
		end

		it "raises an error when the tree is fetched if it isn't well-formed" do
			open_tag = Inversion::Template::ForTag.new( 'foo in bar' )
			@state << open_tag

			expect {
				@state.tree
			}.to raise_error( Inversion::ParseError, /unclosed/i )
		end

		it "calls the #before_appending callback on nodes that are appended to it" do
			node = double( "node", :is_container? => false, :after_appending => nil )
			expect( node ).to receive( :before_appending ).with( @state )

			@state << node
		end

		it "calls the #after_appending callback on nodes that are appended to it" do
			node = double( "node", :is_container? => false, :before_appending => nil )
			expect( node ).to receive( :after_appending ).with( @state )

			@state << node
		end


	end

end

