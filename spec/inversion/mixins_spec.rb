#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../helpers'

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

			expect( result ).to be_an_instance_of( Hash )
			expect( result ).to_not be_equal( testhash )
			expect( result ).to eq({
				'foo' => 1,
				'bar' => {
					'klang' => 'klong',
					'barang' => { 'kerklang' => 'dumdumdum' },
				}
			})
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

			expect( result ).to be_an_instance_of( Hash )
			expect( result ).to_not be_equal( testhash )
			expect( result ).to eq({
				:foo => 1,
				:bar => {
					:klang => 'klong',
					:barang => { :kerklang => 'dumdumdum' },
				}
			})
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
			expect( @obj.render( render_state ) ).to eq( "&lt;something&gt;" )
		end

		it "doesn't escape anything if escaping is disabled" do
			render_state = Inversion::RenderState.new( {}, :escape_format => nil )
			expect( @obj.render( render_state ) ).to eq( "<something>" )
		end

		it "doesn't escape anything if escaping is set to ':none'" do
			render_state = Inversion::RenderState.new( {}, :escape_format => :none )
			expect( @obj.render( render_state ) ).to eq( "<something>" )
		end
	end


	describe Inversion::DataUtilities do

		it "doesn't try to dup immediate objects" do
			expect( Inversion::DataUtilities.deep_copy( nil ) ).to be( nil )
			expect( Inversion::DataUtilities.deep_copy( 112 ) ).to be( 112 )
			expect( Inversion::DataUtilities.deep_copy( true ) ).to be( true )
			expect( Inversion::DataUtilities.deep_copy( false ) ).to be( false )
			expect( Inversion::DataUtilities.deep_copy( :a_symbol ) ).to be( :a_symbol )
		end

		it "doesn't try to dup modules/classes" do
			klass = Class.new
			expect( Inversion::DataUtilities.deep_copy( klass ) ).to be( klass )
		end

		it "doesn't try to dup IOs" do
			data = [ $stdin ]
			expect( Inversion::DataUtilities.deep_copy( data[0] ) ).to be( $stdin )
		end

		it "doesn't try to dup Tempfiles" do
			data = Tempfile.new( 'inversion_deepcopy.XXXXX' )
			expect( Inversion::DataUtilities.deep_copy( data ) ).to be( data )
		end

		it "makes distinct copies of arrays and their members" do
			original = [ 'foom', Set.new([ 1,2 ]), :a_symbol ]

			copy = Inversion::DataUtilities.deep_copy( original )

			expect( copy ).to eq( original )
			expect( copy ).to_not be( original )
			expect( copy[0] ).to eq( original[0] )
			expect( copy[0] ).to_not be( original[0] )
			expect( copy[1] ).to eq( original[1] )
			expect( copy[1] ).to_not be( original[1] )
			expect( copy[2] ).to eq( original[2] )
			expect( copy[2] ).to be( original[2] ) # Immediate
		end

		it "makes recursive copies of deeply-nested Arrays" do
			original = [ 1, [ 2, 3, [4], 5], 6, [7, [8, 9], 0] ]

			copy = Inversion::DataUtilities.deep_copy( original )

			expect( copy ).to eq( original )
			expect( copy ).to_not be( original )
			expect( copy[1] ).to_not be( original[1] )
			expect( copy[1][2] ).to_not be( original[1][2] )
			expect( copy[3] ).to_not be( original[3] )
			expect( copy[3][1] ).to_not be( original[3][1] )
		end

		it "makes distinct copies of Hashes and their members" do
			original = {
				:a => 1,
				'b' => 2,
				3 => 'c',
			}

			copy = Inversion::DataUtilities.deep_copy( original )

			expect( copy ).to eq( original )
			expect( copy ).to_not be( original )
			expect( copy[:a] ).to eq( 1 )
			expect( copy.key( 2 ) ).to eq( 'b' )
			expect( copy.key( 2 ) ).to_not be( original.key(2) )
			expect( copy[3] ).to eq( 'c' )
			expect( copy[3] ).to_not be( original[3] )
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

			expect( copy ).to eq( original )
			expect( copy[:a][:b][:c] ).to eq( 'd' )
			expect( copy[:a][:b][:c] ).to_not be( original[:a][:b][:c] )
			expect( copy[:a][:b][:e] ).to eq( 'f' )
			expect( copy[:a][:b][:e] ).to_not be( original[:a][:b][:e] )
			expect( copy[:a][:g] ).to eq( 'h' )
			expect( copy[:a][:g] ).to_not be( original[:a][:g] )
			expect( copy[:i] ).to eq( 'j' )
			expect( copy[:i] ).to_not be( original[:i] )
		end

		it "copies the default proc of copied Hashes" do
			original = Hash.new {|h,k| h[ k ] = Set.new }

			copy = Inversion::DataUtilities.deep_copy( original )

			expect( copy.default_proc ).to eq( original.default_proc )
		end

		it "preserves taintedness of copied objects" do
			original = Object.new
			original.taint

			copy = Inversion::DataUtilities.deep_copy( original )

			expect( copy ).to_not be( original )
			expect( copy ).to be_tainted()
		end

		it "preserves frozen-ness of copied objects" do
			original = Object.new
			original.freeze

			copy = Inversion::DataUtilities.deep_copy( original )

			expect( copy ).to_not be( original )
			expect( copy ).to be_frozen()
		end
	end
end

