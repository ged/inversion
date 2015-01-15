#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'timeout'
require 'inversion/template'
require 'inversion/template/includetag'

describe Inversion::Template::IncludeTag do

	it "renders the IncludeTag as an empty string" do
		included_path = Pathname.pwd + 'included.tmpl'
		expect( FileTest ).to receive( :exist? ).with( included_path.to_s ).and_return( true )
		expect( IO ).to receive( :read ).with( included_path.to_s ).and_return( 'there,' )

		tmpl = Inversion::Template.new( "hi <?include included.tmpl ?> handsome!" )
		expect( tmpl.render ).to eq( "hi there, handsome!" )
	end


	it "renders debugging comments with the included template path" do
		included_path = Pathname.pwd + 'included.tmpl'
		expect( FileTest ).to receive( :exist? ).with( included_path.to_s ).and_return( true )
		expect( IO ).to receive( :read ).with( included_path.to_s ).and_return( 'there,' )

		tmpl = Inversion::Template.
			new( "hi <?include included.tmpl ?> handsome!", :debugging_comments => true )
		expect( tmpl.render ).to match( /Include "included\.tmpl"/ )
	end


	it "appends the nodes from a separate template onto the including template" do
		included_path = Pathname.pwd + 'included.tmpl'
		expect( FileTest ).to receive( :exist? ).with( included_path.to_s ).and_return( true )
		expect( IO ).to receive( :read ).with( included_path.to_s ).and_return( 'there,' )

		tmpl = Inversion::Template.new( "hi <?include included.tmpl ?> handsome!" )
		expect( tmpl.node_tree.size ).to eq( 4 )
		expect( tmpl.node_tree[0] ).to be_a( Inversion::Template::TextNode )
		expect( tmpl.node_tree[1] ).to be_a( Inversion::Template::IncludeTag )
		expect( tmpl.node_tree[2] ).to be_a( Inversion::Template::TextNode )
		expect( tmpl.node_tree[3] ).to be_a( Inversion::Template::TextNode )
	end


	it "allows the same template to be included multiple times" do
		included_path = Pathname.pwd + 'included.tmpl'
		expect( FileTest ).to receive( :exist? ).
			with( included_path.to_s ).twice.and_return( true )
		expect( IO ).to receive( :read ).
			with( included_path.to_s ).twice.and_return( ' hi' )

		tmpl = Inversion::Template.
			new( "hi<?include included.tmpl ?><?include included.tmpl ?> handsome!" )
		expect( tmpl.render ).to eq( "hi hi hi handsome!" )
	end


	it "raises exception on include loops" do
		included_path = Pathname.pwd + 'included.tmpl'
		expect( FileTest ).to receive( :exist? ).with( included_path.to_s ).and_return( true )
		expect( IO ).to receive( :read ).with( included_path.to_s ).and_return( "<?include included.tmpl ?>" )

		expect {
			Inversion::Template.new( "hi <?include included.tmpl ?> handsome!" )
		}.to raise_error( Inversion::StackError, /Recursive load .+"included.tmpl"/ )
	end


	it "raises exception on complex include loops" do
		top_path    = Pathname.pwd + 'top.tmpl'
		middle_path = Pathname.pwd + 'middle.tmpl'
		bottom_path = Pathname.pwd + 'bottom.tmpl'

		expect( FileTest ).to receive( :exist? ).with( top_path.to_s ).and_return( true )
		expect( IO ).to receive( :read ).with( top_path.to_s ).and_return( "<?include middle.tmpl ?>" )

		expect( FileTest ).to receive( :exist? ).with( middle_path.to_s ).and_return( true )
		expect( IO ).to receive( :read ).with( middle_path.to_s ).and_return( "<?include bottom.tmpl ?>" )

		expect( FileTest ).to receive( :exist? ).with( bottom_path.to_s ).and_return( true )
		expect( IO ).to receive( :read ).with( bottom_path.to_s ).and_return( "<?include top.tmpl ?>" )

		expect {
			Inversion::Template.new( "hi <?include top.tmpl ?> handsome!" )
		}.to raise_error( Inversion::StackError, /Recursive load .+"top.tmpl"/ )
	end
end



