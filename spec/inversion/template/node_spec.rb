#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/node'

describe Inversion::Template::Node do

	let( :concrete_subclass ) { Class.new(Inversion::Template::Node) }

	it "is an abstract class" do
		expect {
			Inversion::Template::Node.new( '' )
		}.to raise_error( NoMethodError, /private method `new'/i )
	end

	it "defaults to using inspect to render itself as a comment" do
		node = concrete_subclass.new( '' )
		expect( node.as_comment_body ).to eq( node.inspect )
	end

	it "isn't a container" do
		node = concrete_subclass.new( '' )
		expect( node ).to_not be_a_container()
	end

	it "knows where it was parsed from if constructed with a position" do
		node = concrete_subclass.new( '', 4, 12 )
		expect( node.location ).to match( /line 4, column 12/ )
	end

	it "knows that it was created from an unknown location if created without a position" do
		node = concrete_subclass.new( '' )
		expect( node.location ).to eq( 'line ??, column ??' )
	end

	it "doesn't raise an exception when the before_appending event callback is called" do
		state = double( "parser state" )
		node = concrete_subclass.new( '' )
		expect {
			node.before_appending( state )
		}.to_not raise_error()
	end

	it "doesn't raise an exception when the after_appending event callback is called" do
		state = double( "parser state" )
		node = concrete_subclass.new( '' )
		expect {
			node.after_appending( state )
		}.to_not raise_error()
	end

	it "doesn't raise an exception when the before_rendering event callback is called" do
		state = double( "render state" )
		node = concrete_subclass.new( '' )
		expect {
			node.before_rendering( state )
		}.to_not raise_error()
	end

	it "doesn't raise an exception when the after_rendering event callback is called" do
		state = double( "render state" )
		node = concrete_subclass.new( '' )
		expect {
			node.after_rendering( state )
		}.to_not raise_error()
	end
end



