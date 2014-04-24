#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :


require_relative '../helpers'

require 'ripper'
require 'inversion/monkeypatches'


describe Inversion, "monkeypatches" do

	describe Inversion::RipperAdditions do

		it "exposes the Ripper::TokenPattern::MatchData's #tokens array" do
			tagpattern = Ripper::TokenPattern.compile( '$(ident) $(sp) $(ident)' )
			matchdata = tagpattern.match( "foo bar" )
			expect( matchdata.tokens.map {|tok| tok[1]} ).to eq([ :on_ident, :on_sp, :on_ident ])
		end

	end


end

