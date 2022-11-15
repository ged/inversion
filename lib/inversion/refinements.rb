# -*- ruby -*-
# vim: set noet nosta sw=4 ts=4 :

require 'inversion' unless defined?( Inversion )
require 'ripper'

# Expose the 'tokens' instance variable of Ripper::TokenPattern::MatchData.
module Inversion::Refinements

	refine Ripper::TokenPattern::MatchData do

		# the array of token tuples
		attr_reader :tokens

	end # refine Ripper::TokenPattern::MatchData

end # module Inversion::Refinements

