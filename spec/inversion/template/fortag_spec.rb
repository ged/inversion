#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'ostruct'
require 'inversion/template/fortag'
require 'inversion/template/attrtag'
require 'inversion/template/textnode'
require 'inversion/renderstate'

describe Inversion::Template::ForTag do


	it "knows which identifiers should be added to the template" do
		tag = Inversion::Template::ForTag.new( 'foo in bar' )
		expect( tag.identifiers ).to eq( [ :bar ] )
	end

	it "can iterate over single items of a collection attribute" do
		tag = Inversion::Template::ForTag.new( 'foo in bar' )

		expect( tag.block_args ).to eq( [ :foo ] )
		expect( tag.enumerator ).to eq( 'bar' )
	end

	it "should render as nothing if the corresponding attribute in the template is unset" do
		render_state = Inversion::RenderState.new( :bar => nil )

		# <?for foo in bar ?>
		tag = Inversion::Template::ForTag.new( 'foo in bar' )

		# [<?attr foo?>]
		tag << Inversion::Template::TextNode.new( '[' )
		tag << Inversion::Template::AttrTag.new( 'foo' )
		tag << Inversion::Template::TextNode.new( ']' )

		expect( tag.render( render_state ) ).to be_nil()
	end

	it "renders each of its subnodes for each iteration, replacing its " +
	   "block arguments with the yielded values" do
		render_state = Inversion::RenderState.new( :bar => %w[monkey goat] )

		# <?for foo in bar ?>
		tag = Inversion::Template::ForTag.new( 'foo in bar' )

		# [<?attr foo?>]
		tag << Inversion::Template::TextNode.new( '[' )
		tag << Inversion::Template::AttrTag.new( 'foo' )
		tag << Inversion::Template::TextNode.new( ']' )

		tag.render( render_state )
		expect( render_state.to_s ).to eq( "[monkey][goat]" )
	end

	it "supports nested iterators" do
		render_state = Inversion::RenderState.new( :tic => [ 'x', 'o'], :tac => ['o', 'x'] )

		# <?for omarker in tic ?><?for imarker in tac ?>
		outer = Inversion::Template::ForTag.new( 'omarker in tic' )
		inner = Inversion::Template::ForTag.new( 'imarker in tac' )

		# [<?attr omarker?>, <?attr imarker?>]
		inner << Inversion::Template::TextNode.new( '[' )
		inner << Inversion::Template::AttrTag.new( 'omarker' )
		inner << Inversion::Template::TextNode.new( ', ' )
		inner << Inversion::Template::AttrTag.new( 'imarker' )
		inner << Inversion::Template::TextNode.new( ']' )

		outer << inner

		outer.render( render_state )
		expect( render_state.to_s ).to eq( "[x, o][x, x][o, o][o, x]" )
	end

	it "supports iterating over a range" do

		# <?for omarker in tic ?><?for imarker in tac ?>
		tag = Inversion::Template::ForTag.new( 'i in rng' )

		tag << Inversion::Template::AttrTag.new( 'i' )
		tag << Inversion::Template::TextNode.new( ' ' )

		render_state = Inversion::RenderState.new( :rng => 0..10 )
		tag.render( render_state )
		expect( render_state.to_s ).to eq( "0 1 2 3 4 5 6 7 8 9 10 " )
	end

	it "raises a ParseError if a keyword other than 'in' is used" do
		expect {
			Inversion::Template::ForTag.new( 'foo begin bar' )
		}.to raise_error( Inversion::ParseError, /invalid/i )
	end

	context "multidimensional collections" do

		it "can be expanded into multiple block arguments" do
			tag = Inversion::Template::ForTag.new( 'splip, splorp in splap' )

			expect( tag.block_args ).to eq( [ :splip, :splorp ] )
			expect( tag.enumerator ).to eq( 'splap' )
		end


		it "can be expanded into multiple block arguments (sans spaces)" do
			tag = Inversion::Template::ForTag.new( 'splip,splorp,sploop in splap' )

			expect( tag.block_args ).to eq( [ :splip, :splorp, :sploop ] )
			expect( tag.enumerator ).to eq( 'splap' )
		end

		it "can be expanded into multiple block arguments from hash pairs" do
			tag = Inversion::Template::ForTag.new( 'key, value in splap' )

			# [<?attr key?> translates to <?attr value?>]
			tag << Inversion::Template::TextNode.new( '[' )
			tag << Inversion::Template::AttrTag.new( 'key' )
			tag << Inversion::Template::TextNode.new( ' translates to ' )
			tag << Inversion::Template::AttrTag.new( 'value' )
			tag << Inversion::Template::TextNode.new( ']' )

			expect( tag.block_args ).to eq( [ :key, :value ] )
			expect( tag.enumerator ).to eq( 'splap' )

			render_state = Inversion::RenderState.new( :splap => {'one' => 'uno', 'two' => 'dos'} )
			tag.render( render_state )

			expect( render_state.to_s ).to eq( '[one translates to uno][two translates to dos]' )
		end

		it "can be expanded into multiple block arguments with complex values" do
			# [<?attr key?> translates to <?attr value?>]
			tree = Inversion::Parser.new( nil ).parse( <<-"END_TEMPLATE" )
			<?for scope, visibilities in method_list ?>
			<?call scope.first ?> (<?call scope.length ?>) => <?call visibilities[:name] ?>
			<?if visibilities[:variants] ?>AKA: <?call scope[1..-1].join(', ') ?><?end if ?>
			<?end for ?>
			END_TEMPLATE

			# Drop the non-container nodes at the beginning and end
			tree.delete_if {|node| !node.container? }

			method_list = {
				[:foo, :foom, :foom_detail] => { :name => 'foo', :variants => true },
				[:ch] => { :name => 'ch', :variants => false },
			}

			render_state = Inversion::RenderState.new( :method_list => method_list )
			tree.first.render( render_state )

			expect( render_state.to_s ).to match( /foo \(3\) => foo\s+AKA: foom, foom_detail/ )
			expect( render_state.to_s ).to match( /ch \(1\) => ch/ )
		end

		it "preserves an array of subhashes" do
			tree = Inversion::Parser.new( nil ).parse( <<-"END_TEMPLATE" )
			<?for subhash in the_hash[:a] ?>
				Subhash is a <?call subhash.class.name ?>
			<?end for ?>
			END_TEMPLATE

			# Drop the non-container nodes at the beginning and end
			tree.delete_if {|node| !node.container? }

			the_hash = { :a => [ { :b => 'foo', :c => 'bar' }, { :d => 'blah', :e => 'blubb'} ] }

			render_state = Inversion::RenderState.new( :the_hash => the_hash )
			tree.first.render( render_state )

			expect( render_state.to_s ).to match( /Subhash is a Hash/i )
		end

	end


	context "manual examples" do

		it "renders the hexdump example as expected" do
			tmpl = Inversion::Template.new( <<-END_TEMPLATE )
			<section class="hexdump">
			<?for byte, index in frame.header.each_byte.with_index ?>
				<?if index.modulo(8).zero? ?>
					<?if index.nonzero? ?>
				</span><br />
					<?end if ?>
				<span class="row"><?attr "0x%08x" % index ?>:
				<?end if ?>
				&nbsp;<code><?attr "0x%02x" % byte ?></code>
			<?end for ?>
				</span>
			</section>
			END_TEMPLATE

			frame = OpenStruct.new
			frame.header = [
				0x89, 0x05, 0x48, 0x65,  0x6c, 0x6c, 0x6f, 0x82,
				0x7E, 0x01, 0x00, 0x8a,  0x05, 0x48, 0x65, 0x6c,
				0x6c, 0x6f, 0x82, 0x7F,  0x00, 0x00, 0x00, 0x00,
				0x00, 0x01, 0x00, 0x00,  0x13
			].pack( 'C*' )

			tmpl.frame = frame
			output = tmpl.render

			expect( output.gsub( /\t+/, '' ) ).to eq( (<<-END_OUTPUT).gsub( /\t+/, '' ) )
			<section class="hexdump">
				<span class="row">0x00000000:
				&nbsp;<code>0x89</code>
				&nbsp;<code>0x05</code>
				&nbsp;<code>0x48</code>
				&nbsp;<code>0x65</code>
				&nbsp;<code>0x6c</code>
				&nbsp;<code>0x6c</code>
				&nbsp;<code>0x6f</code>
				&nbsp;<code>0x82</code>
				</span><br />
				<span class="row">0x00000008:
				&nbsp;<code>0x7e</code>
				&nbsp;<code>0x01</code>
				&nbsp;<code>0x00</code>
				&nbsp;<code>0x8a</code>
				&nbsp;<code>0x05</code>
				&nbsp;<code>0x48</code>
				&nbsp;<code>0x65</code>
				&nbsp;<code>0x6c</code>
				</span><br />
				<span class="row">0x00000010:
				&nbsp;<code>0x6c</code>
				&nbsp;<code>0x6f</code>
				&nbsp;<code>0x82</code>
				&nbsp;<code>0x7f</code>
				&nbsp;<code>0x00</code>
				&nbsp;<code>0x00</code>
				&nbsp;<code>0x00</code>
				&nbsp;<code>0x00</code>
				</span><br />
				<span class="row">0x00000018:
				&nbsp;<code>0x00</code>
				&nbsp;<code>0x01</code>
				&nbsp;<code>0x00</code>
				&nbsp;<code>0x00</code>
				&nbsp;<code>0x13</code>
				</span>
			</section>
			END_OUTPUT
		end
	end
end



