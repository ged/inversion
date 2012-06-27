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


	describe Inversion::DataUtilities do

		it "doesn't try to dup immediate objects" do
			Inversion::DataUtilities.deep_copy( nil ).should be( nil )
			Inversion::DataUtilities.deep_copy( 112 ).should be( 112 )
			Inversion::DataUtilities.deep_copy( true ).should be( true )
			Inversion::DataUtilities.deep_copy( false ).should be( false )
			Inversion::DataUtilities.deep_copy( :a_symbol ).should be( :a_symbol )
		end

		it "doesn't try to dup modules/classes" do
			klass = Class.new
			Inversion::DataUtilities.deep_copy( klass ).should be( klass )
		end

		it "makes distinct copies of arrays and their members" do
			original = [ 'foom', Set.new([ 1,2 ]), :a_symbol ]

			copy = Inversion::DataUtilities.deep_copy( original )

			copy.should == original
			copy.should_not be( original )
			copy[0].should == original[0]
			copy[0].should_not be( original[0] )
			copy[1].should == original[1]
			copy[1].should_not be( original[1] )
			copy[2].should == original[2]
			copy[2].should be( original[2] ) # Immediate
		end

		it "makes recursive copies of deeply-nested Arrays" do
			original = [ 1, [ 2, 3, [4], 5], 6, [7, [8, 9], 0] ]

			copy = Inversion::DataUtilities.deep_copy( original )

			copy.should == original
			copy.should_not be( original )
			copy[1].should_not be( original[1] )
			copy[1][2].should_not be( original[1][2] )
			copy[3].should_not be( original[3] )
			copy[3][1].should_not be( original[3][1] )
		end

		it "makes distinct copies of Hashes and their members" do
			original = {
				:a => 1,
				'b' => 2,
				3 => 'c',
			}

			copy = Inversion::DataUtilities.deep_copy( original )

			copy.should == original
			copy.should_not be( original )
			copy[:a].should == 1
			copy.key( 2 ).should == 'b'
			copy.key( 2 ).should_not be( original.key(2) )
			copy[3].should == 'c'
			copy[3].should_not be( original[3] )
		end

		it "makes distinct copies of deeply-nested Hashes" do
			original = {
				:a => {
					:b => {
						:c => 'd',
						:e => 'f',
					},
					:g => 'h',
				},
				:i => 'j',
			}

			copy = Inversion::DataUtilities.deep_copy( original )

			copy.should == original
			copy[:a][:b][:c].should == 'd'
			copy[:a][:b][:c].should_not be( original[:a][:b][:c] )
			copy[:a][:b][:e].should == 'f'
			copy[:a][:b][:e].should_not be( original[:a][:b][:e] )
			copy[:a][:g].should == 'h'
			copy[:a][:g].should_not be( original[:a][:g] )
			copy[:i].should == 'j'
			copy[:i].should_not be( original[:i] )
		end

		it "copies the default proc of copied Hashes" do
			original = Hash.new {|h,k| h[ k ] = Set.new }

			copy = Inversion::DataUtilities.deep_copy( original )

			copy.default_proc.should == original.default_proc
		end

		it "preserves taintedness of copied objects" do
			original = Object.new
			original.taint

			copy = Inversion::DataUtilities.deep_copy( original )

			copy.should_not be( original )
			copy.should be_tainted()
		end

		it "preserves frozen-ness of copied objects" do
			original = Object.new
			original.freeze

			copy = Inversion::DataUtilities.deep_copy( original )

			copy.should_not be( original )
			copy.should be_frozen()
		end
	end
end

