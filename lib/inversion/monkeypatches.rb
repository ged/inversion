#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:

require 'inversion' unless defined?( Inversion )

# A collection of monkeypatches for various things.

require 'ripper'

# Expose the 'tokens' instance variable of Ripper::TokenPattern::MatchData
module Inversion::RipperAdditions

	##
	# :return: [Array<Array<>>] the array of token tuples
	attr_reader :tokens

end

class Ripper::TokenPattern::MatchData
	include Inversion::RipperAdditions
end # class Ripper::TokenPattern::MatchData

