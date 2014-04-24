#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/fortag'
require 'inversion/template/textnode'
require 'inversion/template/endtag'
require 'inversion/renderstate'

describe Inversion::Template::EndTag do

	before( :each ) do
		@tag = Inversion::Template::EndTag.new
	end


	it "doesn't render as anything" do
		renderstate = Inversion::RenderState.new
		expect( @tag.render(renderstate) ).to be_nil()
	end

	it "can render itself as a comment body that outputs what it closes" do
		# <?for i IN foo ?>...<?end ?>
		template = Inversion::Template.
			new( "<?for foo in bar ?>Chunkers<?end ?>", :debugging_comments => true )
		template.bar = [ :an_item ]
		expect( template.render ).to match( /<!-- End of For: { foo IN template.bar } -->/ )
	end

	it "closes the parse state's currently-open container node before it's appended" do
		container = double( "container node", :tagname => 'for', :location => nil )
		parserstate = double( "parser state" )

		expect( parserstate ).to receive( :pop ).and_return( container )

		@tag.before_appending( parserstate )
	end

	context "with a body" do

		before( :each ) do
			@tag = Inversion::Template::EndTag.new( 'if' )
		end

		it "raises an error on the addition of a mismatched end tag" do
			state = Inversion::Parser::State.new( :template )
			opener = Inversion::Template::ForTag.new( 'foo in bar' )
			state << opener

			expect {
				@tag.before_appending( state )
			}.to raise_error( Inversion::ParseError, /unbalanced/i )
		end

	end

end



