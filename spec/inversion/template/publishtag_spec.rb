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


	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	it "raises a parse error if the body isn't a simple attribute" do
		expect {
			Inversion::Template::PublishTag.new( 'a.non-identifier' )
		}.should raise_exception( Inversion::ParseError, /malformed key/i )
	end


	it "doesn't render its contents in the template it's declared in" do
		Inversion::Template.new( "<?publish foo ?>Some stuff<?end ?>" ).render.should == ''
	end


	it "publishes its rendered nodes to the render state when rendered" do
		contenttag = Inversion::Template::TextNode.new( 'elveses' )
		publishtag = Inversion::Template::PublishTag.new( 'eventname' )
		publishtag << contenttag

		subscriber = TestSubscriber.new
		renderstate = Inversion::RenderState.new
		renderstate.subscribe( :eventname, subscriber )

		publishtag.render( renderstate )

		subscriber.published_nodes.should == [ 'elveses' ]
	end

end


