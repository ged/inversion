#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent.parent.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'timeout'
require 'rspec'
require 'spec/lib/helpers'
require 'inversion/template'
require 'inversion/template/includetag'

describe Inversion::Template::IncludeTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	it "renders the IncludeTag as an empty string" do
		included_path = Pathname.pwd + 'included.tmpl'
		FileTest.stub( :exist? ).with( included_path.to_s ).and_return true
		IO.stub( :read ).with( included_path.to_s ).and_return( 'there,' )

		tmpl = Inversion::Template.new( "hi <?include included.tmpl ?> handsome!" )
		tmpl.render.should == "hi there, handsome!"
	end


	it "renders debugging comments with the included template path" do
		included_path = Pathname.pwd + 'included.tmpl'
		FileTest.stub( :exist? ).with( included_path.to_s ).and_return true
		IO.stub( :read ).with( included_path.to_s ).and_return( 'there,' )

		tmpl = Inversion::Template.
			new( "hi <?include included.tmpl ?> handsome!", :debugging_comments => true )
		tmpl.render.should =~ /Include "included\.tmpl"/
	end


	it "appends the nodes from a separate template onto the including template" do
		included_path = Pathname.pwd + 'included.tmpl'
		FileTest.stub( :exist? ).with( included_path.to_s ).and_return true
		IO.stub( :read ).with( included_path.to_s ).and_return( 'there,' )

		tmpl = Inversion::Template.new( "hi <?include included.tmpl ?> handsome!" )
		tmpl.node_tree.should have(4).members
		tmpl.node_tree[0].should be_a( Inversion::Template::TextNode )
		tmpl.node_tree[1].should be_a( Inversion::Template::IncludeTag )
		tmpl.node_tree[2].should be_a( Inversion::Template::TextNode )
		tmpl.node_tree[3].should be_a( Inversion::Template::TextNode )
	end


	it "allows the same template to be included multiple times" do
		included_path = Pathname.pwd + 'included.tmpl'
		FileTest.stub( :exist? ).with( included_path.to_s ).and_return true
		IO.stub( :read ).with( included_path.to_s ).and_return( ' hi' )

		tmpl = Inversion::Template.
			new( "hi<?include included.tmpl ?><?include included.tmpl ?> handsome!" )
		tmpl.render.should == "hi hi hi handsome!"
	end


	it "raises exception on include loops" do
		included_path = Pathname.pwd + 'included.tmpl'
		FileTest.stub( :exist? ).with( included_path.to_s ).and_return true
		IO.stub( :read ).with( included_path.to_s ).and_return( "<?include included.tmpl ?>" )

		expect {
			Inversion::Template.new( "hi <?include included.tmpl ?> handsome!" )
		}.to raise_error( Inversion::StackError, /Recursive include .+"included.tmpl"/ )
	end


	it "raises exception on complex include loops" do
		top_path    = Pathname.pwd + 'top.tmpl'
		middle_path = Pathname.pwd + 'middle.tmpl'
		bottom_path = Pathname.pwd + 'bottom.tmpl'

		FileTest.stub( :exist? ).with( top_path.to_s ).and_return true
		IO.stub( :read ).with( top_path.to_s ).and_return( "<?include middle.tmpl ?>" )

		FileTest.stub( :exist? ).with( middle_path.to_s ).and_return true
		IO.stub( :read ).with( middle_path.to_s ).and_return( "<?include bottom.tmpl ?>" )

		FileTest.stub( :exist? ).with( bottom_path.to_s ).and_return true
		IO.stub( :read ).with( bottom_path.to_s ).and_return( "<?include top.tmpl ?>" )

		expect {
			Inversion::Template.new( "hi <?include top.tmpl ?> handsome!" )
		}.to raise_error( Inversion::StackError, /Recursive include .+"top.tmpl"/ )
	end
end



