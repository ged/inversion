#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../helpers'

begin
	require 'tilt'
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
		expect( Tilt['layout.tmpl'] ).to eq( Inversion::TiltWrapper )
	end

	it "merges locals with template attributes upon evaluation" do
		expect( File ).to receive( :open ).with( 'test.tmpl', 'rb' ).and_return( '<?attr foo ?>' )
		expect( Tilt.new( 'test.tmpl' ).render( Object.new, :foo => 'Booyakasha!' ) ).to eq( 'Booyakasha!' )
	end

	it "merges the 'scope' object if it responds_to #to_h" do
		scope = Object.new
		def scope.to_h; { :message => "Respek!" }; end
		expect( File ).to receive( :open ).with( 'test.tmpl', 'rb' ).and_return( '<?attr message ?>' )
		expect( Tilt.new( 'test.tmpl' ).render( scope, {} ) ).to eq( 'Respek!' )
	end

end

