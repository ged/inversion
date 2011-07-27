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
require 'ostruct'
require 'spec/lib/helpers'
require 'inversion/template/begintag'
require 'inversion/template/textnode'
require 'inversion/template/attrtag'
require 'inversion/template/rescuetag'
require 'inversion/template/endtag'
require 'inversion/renderstate'

describe Inversion::Template::BeginTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	context "without any rescue clauses" do

		before( :each ) do
			@tag = Inversion::Template::BeginTag.new( ' ' )
			@tag << Inversion::Template::AttrTag.new( 'foo.baz' )
			@tag << Inversion::Template::TextNode.new( ':the stuff after the attr' )
		end

		it "should render its subnodes as-is if none of them raise an exception"  do
			renderstate = Inversion::RenderState.new( :foo => OpenStruct.new(:baz => 'the body') )
			renderstate << @tag
			renderstate.to_s.should == 'the body:the stuff after the attr'
		end

		it "should use the configured error behavior of the template if a subnode raises any exception" do
			renderstate = Inversion::RenderState.new
			renderstate << @tag
			renderstate.to_s.should =~ /NoMethodError/
			renderstate.to_s.should_not =~ /the stuff after the attr/i
		end

	end

	context "with a single rescue clause with no exception type" do

		before( :each ) do
			@tag = Inversion::Template::BeginTag.new( ' ' )

			@attrtag = Inversion::Template::AttrTag.new( 'foo.baz' )
			@normal_textnode = Inversion::Template::TextNode.new( ':the stuff after the attr' )
			@rescue_textnode = Inversion::Template::TextNode.new( 'rescue stuff' )

			@tag << @attrtag << @normal_textnode
			@tag << Inversion::Template::RescueTag.new( '' )
			@tag << @rescue_textnode

			@renderstate = Inversion::RenderState.new
		end

		it "contains one rescue clause for RuntimeErrors" do
			@tag.rescue_clauses.should == [ [[::RuntimeError], [@rescue_textnode]] ]
		end

		it "should render its subnodes as-is if none of them raise an exception"  do
			renderstate = Inversion::RenderState.new( :foo => OpenStruct.new(:baz => 'the body') )
			renderstate << @tag
			renderstate.to_s.should == 'the body:the stuff after the attr'
		end

		it "should render the rescue section if a subnode raises a RuntimeError"  do
			fooobj = Object.new
			def fooobj.baz; raise "An exception"; end

			renderstate = Inversion::RenderState.new( :foo => fooobj )
			renderstate << @tag
			renderstate.to_s.should == 'rescue stuff'
		end

		it "should use the configured error behavior of the template if a subnode raises an " +
		   "exception other than RuntimeError" do
			fooobj = Object.new
			def fooobj.baz; raise Errno::ENOENT, "No such file or directory"; end

			renderstate = Inversion::RenderState.new( :foo => fooobj )
			renderstate << @tag
			renderstate.to_s.should =~ /ENOENT/i
			renderstate.to_s.should_not =~ /rescue stuff/i
			renderstate.to_s.should_not =~ /the stuff after the attr/i
		end
	end


	context "with a single rescue clause with an exception type" do
		before( :each ) do
			@tag = Inversion::Template::BeginTag.new( ' ' )

			@attrtag = Inversion::Template::AttrTag.new( 'foo.baz' )
			@normal_textnode = Inversion::Template::TextNode.new( ':the stuff after the attr' )
			@rescue_textnode = Inversion::Template::TextNode.new( 'rescue stuff' )

			@tag << @attrtag << @normal_textnode
			@tag << Inversion::Template::RescueTag.new( 'SystemCallError' )
			@tag << @rescue_textnode

			@renderstate = Inversion::RenderState.new
		end

		it "contains one rescue clause for the specified exception type" do
			@tag.rescue_clauses.should == [ [[::SystemCallError], [@rescue_textnode]] ]
		end

		it "should render its subnodes as-is if none of them raise an exception"  do
			renderstate = Inversion::RenderState.new( :foo => OpenStruct.new(:baz => 'the body') )
			renderstate << @tag
			renderstate.to_s.should == 'the body:the stuff after the attr'
		end

		it "should render the rescue section if a subnode raises the specified exception type"  do
			fooobj = Object.new
			def fooobj.baz; raise Errno::ENOENT, "no such file or directory"; end

			renderstate = Inversion::RenderState.new( :foo => fooobj )
			renderstate << @tag
			renderstate.to_s.should == 'rescue stuff'
		end

		it "should use the configured error behavior of the template if a subnode raises an " +
		   "exception other than the specified type" do
			fooobj = Object.new
			def fooobj.baz; raise "SPlat!"; end

			renderstate = Inversion::RenderState.new( :foo => fooobj )
			renderstate << @tag
			renderstate.to_s.should =~ /RuntimeError/i
			renderstate.to_s.should_not =~ /rescue stuff/i
			renderstate.to_s.should_not =~ /the stuff after the attr/i
		end
	end

	context "with multiple rescue clauses" do
		before( :each ) do
			@tag = Inversion::Template::BeginTag.new( ' ' )

			@attrtag = Inversion::Template::AttrTag.new( 'foo.baz' )
			@normal_textnode = Inversion::Template::TextNode.new( ':the stuff after the attr' )
			@rescue_textnode = Inversion::Template::TextNode.new( 'rescue stuff' )
			@rescue_textnode2 = Inversion::Template::TextNode.new( 'alternative rescue stuff' )

			@tag << @attrtag << @normal_textnode
			@tag << Inversion::Template::RescueTag.new( '' )
			@tag << @rescue_textnode
			@tag << Inversion::Template::RescueTag.new( 'Errno::ENOENT, Errno::EWOULDBLOCK' )
			@tag << @rescue_textnode2

			@renderstate = Inversion::RenderState.new
		end

		it "contains a rescue tuple for each rescue tag" do
			@tag.rescue_clauses.should == [
				[[::RuntimeError], [@rescue_textnode]],
				[[Errno::ENOENT, Errno::EWOULDBLOCK], [@rescue_textnode2]],
			]
		end

		it "should render its subnodes as-is if none of them raise an exception"  do
			renderstate = Inversion::RenderState.new( :foo => OpenStruct.new(:baz => 'the body') )
			renderstate << @tag
			renderstate.to_s.should == 'the body:the stuff after the attr'
		end

		it "should render the first rescue section if a subnode raises the exception it " +
		   "specifies"  do
			fooobj = Object.new
			def fooobj.baz; raise "An exception"; end

			renderstate = Inversion::RenderState.new( :foo => fooobj )
			renderstate << @tag
			renderstate.to_s.should == 'rescue stuff'
		end

		it "should render the second rescue section if a subnode raises the exception it " +
		   "specifies"  do
			fooobj = Object.new
			def fooobj.baz; raise Errno::ENOENT, "no such file or directory"; end

			renderstate = Inversion::RenderState.new( :foo => fooobj )
			renderstate << @tag
			renderstate.to_s.should == 'alternative rescue stuff'
		end

		it "should use the configured error behavior of the template if a subnode raises an " +
		   "exception other than those specified by the rescue clauses" do
			fooobj = Object.new
			def fooobj.baz; raise Errno::ENOMEM, "All out!"; end

			renderstate = Inversion::RenderState.new( :foo => fooobj )
			renderstate << @tag
			renderstate.to_s.should =~ /ENOMEM/i
			renderstate.to_s.should_not =~ /rescue stuff/i
			renderstate.to_s.should_not =~ /the stuff after the attr/i
		end
	end

end
