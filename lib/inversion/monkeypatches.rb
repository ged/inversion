#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:

require 'inversion' unless defined?( Inversion )
require 'ripper'

# Monkeypatch mixin to expose the 'tokens' instance variable of
# Ripper::TokenPattern::MatchData. Included in Ripper::TokenPattern::MatchData.
module Inversion::RipperAdditions

	# the array of token tuples
	attr_reader :tokens

end

# :stopdoc:
class Ripper::TokenPattern::MatchData
	include Inversion::RipperAdditions
end

