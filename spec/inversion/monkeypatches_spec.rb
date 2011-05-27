#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'ripper'

require 'rspec'
require 'spec/lib/helpers'

require 'inversion/monkeypatches'


describe Inversion, "monkeypatches" do

	describe Inversion::RipperAdditions do

		it "exposes the Ripper::TokenPattern::MatchData's #tokens array" do
			tagpattern = Ripper::TokenPattern.compile( '$(ident) $(sp) $(ident)' )
			matchdata = tagpattern.match( "foo bar" )
			matchdata.tokens.map {|tok| tok[1] }.should == [ :on_ident, :on_sp, :on_ident ]
		end

	end


end

