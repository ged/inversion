#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'spec/lib/helpers'

require 'inversion/mixins'


describe Inversion, "mixins" do

	describe Inversion::HashUtilities do
		it "includes a function for stringifying Hash keys" do
			testhash = {
				:foo => 1,
				:bar => {
					:klang => 'klong',
					:barang => { :kerklang => 'dumdumdum' },
				}
			}

			result = Inversion::HashUtilities.stringify_keys( testhash )

			result.should be_an_instance_of( Hash )
			result.should_not be_equal( testhash )
			result.should == {
				'foo' => 1,
				'bar' => {
					'klang' => 'klong',
					'barang' => { 'kerklang' => 'dumdumdum' },
				}
			}
		end


		it "includes a function for symbolifying Hash keys" do
			testhash = {
				'foo' => 1,
				'bar' => {
					'klang' => 'klong',
					'barang' => { 'kerklang' => 'dumdumdum' },
				}
			}

			result = Inversion::HashUtilities.symbolify_keys( testhash )

			result.should be_an_instance_of( Hash )
			result.should_not be_equal( testhash )
			result.should == {
				:foo => 1,
				:bar => {
					:klang => 'klong',
					:barang => { :kerklang => 'dumdumdum' },
				}
			}
		end

	end


	describe Inversion::AbstractClass do

		context "mixed into a class" do
			it "will cause the including class to hide its ::new method" do
				testclass = Class.new { include Inversion::AbstractClass }

				expect {
					testclass.new
				}.to raise_error( NoMethodError, /private/ )
			end

		end


		context "mixed into a superclass" do

			before(:each) do
				testclass = Class.new {
					include Inversion::AbstractClass
					pure_virtual :test_method
				}
				subclass = Class.new( testclass )
				@instance = subclass.new
			end


			it "raises a NotImplementedError when unimplemented API methods are called" do
				expect {
					@instance.test_method
				}.to raise_error( NotImplementedError, /does not provide an implementation of/ )
			end

			it "declares the virtual methods so that they can be used with arguments under Ruby 1.9" do
				expect {
					@instance.test_method( :some, :arguments )
				}.to raise_error( NotImplementedError, /does not provide an implementation of/ )
			end

		end

	end


	describe Inversion::Escaping do

		before( :each ) do
			objclass = Class.new do
				include Inversion::Escaping

				def render( state )
					return self.escape( "<something>", state )
				end
			end
			@obj = objclass.new
		end

		it "adds configurable escaping to including classes" do
			render_state = Inversion::RenderState.new( {}, :escape_format => :html )
			@obj.render( render_state ).should == "&lt;something&gt;"
		end

		it "doesn't escape anything if escaping is disabled" do
			render_state = Inversion::RenderState.new( {}, :escape_format => nil )
			@obj.render( render_state ).should == "<something>"
		end

		it "doesn't escape anything if escaping is set to ':none'" do
			render_state = Inversion::RenderState.new( {}, :escape_format => :none )
			@obj.render( render_state ).should == "<something>"
		end
	end

end

