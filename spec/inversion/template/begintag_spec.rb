#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'ostruct'
require 'inversion/template/begintag'
require 'inversion/template/textnode'
require 'inversion/template/attrtag'
require 'inversion/template/rescuetag'
require 'inversion/template/endtag'
require 'inversion/renderstate'

describe Inversion::Template::BeginTag do


	context "without any rescue clauses" do

		before( :each ) do
			@tag = Inversion::Template::BeginTag.new( ' ' )
			@tag << Inversion::Template::AttrTag.new( 'foo.baz' )
			@tag << Inversion::Template::TextNode.new( ':the stuff after the attr' )
		end

		it "renders its subnodes as-is if none of them raise an exception"  do
			renderstate = Inversion::RenderState.new( :foo => OpenStruct.new(:baz => 'the body') )
			renderstate << @tag
			expect( renderstate.to_s ).to eq( 'the body:the stuff after the attr' )
		end

		it "uses the configured error behavior of the template if a subnode raises any exception" do
			renderstate = Inversion::RenderState.new
			renderstate << @tag
			expect( renderstate.to_s ).to match( /NoMethodError/ )
			expect( renderstate.to_s ).to_not match( /the stuff after the attr/i )
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
			expect( @tag.rescue_clauses ).to eq([ [[::RuntimeError], [@rescue_textnode]] ])
		end

		it "renders its subnodes as-is if none of them raise an exception"  do
			renderstate = Inversion::RenderState.new( :foo => OpenStruct.new(:baz => 'the body') )
			renderstate << @tag
			expect( renderstate.to_s ).to eq( 'the body:the stuff after the attr' )
		end

		it "renders the rescue section if a subnode raises a RuntimeError"  do
			fooobj = Object.new
			def fooobj.baz; raise "An exception"; end

			renderstate = Inversion::RenderState.new( :foo => fooobj )
			renderstate << @tag
			expect( renderstate.to_s ).to eq( 'rescue stuff' )
		end

		it "uses the configured error behavior of the template if a subnode raises an " +
		   "exception other than RuntimeError" do
			fooobj = Object.new
			def fooobj.baz; raise Errno::ENOENT, "No such file or directory"; end

			renderstate = Inversion::RenderState.new( :foo => fooobj )
			renderstate << @tag
			expect( renderstate.to_s ).to match( /ENOENT/i )
			expect( renderstate.to_s ).to_not match( /rescue stuff/i )
			expect( renderstate.to_s ).to_not match( /the stuff after the attr/i )
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
			expect( @tag.rescue_clauses ).to eq( [ [[::SystemCallError], [@rescue_textnode]] ] )
		end

		it "renders its subnodes as-is if none of them raise an exception"  do
			renderstate = Inversion::RenderState.new( :foo => OpenStruct.new(:baz => 'the body') )
			renderstate << @tag
			expect( renderstate.to_s ).to eq( 'the body:the stuff after the attr' )
		end

		it "renders the rescue section if a subnode raises the specified exception type"  do
			fooobj = Object.new
			def fooobj.baz; raise Errno::ENOENT, "no such file or directory"; end

			renderstate = Inversion::RenderState.new( :foo => fooobj )
			renderstate << @tag
			expect( renderstate.to_s ).to eq( 'rescue stuff' )
		end

		it "uses the configured error behavior of the template if a subnode raises an " +
		   "exception other than the specified type" do
			fooobj = Object.new
			def fooobj.baz; raise "SPlat!"; end

			renderstate = Inversion::RenderState.new( :foo => fooobj )
			renderstate << @tag
			expect( renderstate.to_s ).to match( /RuntimeError/i )
			expect( renderstate.to_s ).to_not match( /rescue stuff/i )
			expect( renderstate.to_s ).to_not match( /the stuff after the attr/i )
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
			expect( @tag.rescue_clauses ).to eq([
				[[::RuntimeError], [@rescue_textnode]],
				[[Errno::ENOENT, Errno::EWOULDBLOCK], [@rescue_textnode2]],
			])
		end

		it "renders its subnodes as-is if none of them raise an exception"  do
			renderstate = Inversion::RenderState.new( :foo => OpenStruct.new(:baz => 'the body') )
			renderstate << @tag
			expect( renderstate.to_s ).to eq( 'the body:the stuff after the attr' )
		end

		it "renders the first rescue section if a subnode raises the exception it " +
		   "specifies"  do
			fooobj = Object.new
			def fooobj.baz; raise "An exception"; end

			renderstate = Inversion::RenderState.new( :foo => fooobj )
			renderstate << @tag
			expect( renderstate.to_s ).to eq( 'rescue stuff' )
		end

		it "renders the second rescue section if a subnode raises the exception it " +
		   "specifies"  do
			fooobj = Object.new
			def fooobj.baz; raise Errno::ENOENT, "no such file or directory"; end

			renderstate = Inversion::RenderState.new( :foo => fooobj )
			renderstate << @tag
			expect( renderstate.to_s ).to eq( 'alternative rescue stuff' )
		end

		it "uses the configured error behavior of the template if a subnode raises an " +
		   "exception other than those specified by the rescue clauses" do
			fooobj = Object.new
			def fooobj.baz; raise Errno::ENOMEM, "All out!"; end

			renderstate = Inversion::RenderState.new( :foo => fooobj )
			renderstate << @tag
			expect( renderstate.to_s ).to match( /ENOMEM/i )
			expect( renderstate.to_s ).to_not match( /rescue stuff/i )
			expect( renderstate.to_s ).to_not match( /the stuff after the attr/i )
		end
	end

end
