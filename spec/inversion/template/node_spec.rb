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
require 'inversion/template/node'

describe Inversion::Template::Node do

	let( :concrete_subclass ) { Class.new(Inversion::Template::Node) }

	it "is an abstract class" do
		expect {
			Inversion::Template::Node.new
		}.to raise_exception( NoMethodError, /private method `new'/i )
	end

	it "defaults to using inspect to render itself as a comment" do
		node = concrete_subclass.new
		node.as_comment_body.should == node.inspect
	end

end

