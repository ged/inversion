#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/publishtag'

describe Inversion::Template::PublishTag do

	class TestSubscriber
		def initialize
			@published_nodes = []
		end

		attr_reader :published_nodes

		def publish( *nodes )
			@published_nodes.push( *nodes )
		end
	end # class TestSubscriber



	it "raises a parse error if the body isn't a simple attribute" do
		expect {
			Inversion::Template::PublishTag.new( 'a.non-identifier' )
		}.to raise_error( Inversion::ParseError, /malformed key/i )
	end


	it "doesn't render its contents in the template it's declared in" do
		expect( Inversion::Template.new( "<?publish foo ?>Some stuff<?end ?>" ).render ).to eq( '' )
	end


	it "publishes its rendered nodes to the render state when rendered" do
		contenttag = Inversion::Template::TextNode.new( 'elveses' )
		publishtag = Inversion::Template::PublishTag.new( 'eventname' )
		publishtag << contenttag

		subscriber = TestSubscriber.new
		renderstate = Inversion::RenderState.new
		renderstate.subscribe( :eventname, subscriber )

		publishtag.render( renderstate )

		expect( subscriber.published_nodes ).to eq( [ 'elveses' ] )
	end

end


