#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent.parent
	libdir  = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s )  unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'spec/lib/helpers'

begin
	require 'inversion/tilt'
	$tilt_support = true
rescue LoadError => err
	warn "Tilt support testing disabled: %p: %s" % [ err.class, err.message ]
	$tilt_support = false
end

describe "Tilt support", :if => $tilt_support do

	before( :all ) do
		setup_logging( :fatal )
	end

	it "registers itself with Tilt" do
		Tilt['layout.tmpl'].should == Inversion::TiltWrapper
	end

	it "merges locals with template attributes upon evaluation" do
		File.stub( :binread ).with( 'test.tmpl' ).and_return( '<?attr foo ?>' )
		Tilt.new( 'test.tmpl' ).render( Object.new, :foo => 'Booyakasha!' ).should == 'Booyakasha!'
	end

	it "merges the 'scope' object if it responds_to #to_h" do
		scope = Object.new
		def scope.to_h; { :message => "Respek!" }; end
		File.stub( :binread ).with( 'test.tmpl' ).and_return( '<?attr message ?>' )
		Tilt.new( 'test.tmpl' ).render( scope, {} ).should == 'Respek!'
	end

end

