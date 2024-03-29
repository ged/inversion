# -*- ruby -*-
# vim: set noet nosta sw=4 ts=4 :

require 'loggability'

require 'ripper'
require 'inversion/template' unless defined?( Inversion::Template )
require 'inversion/template/tag'

using Inversion::Refinements


# The base class for Inversion tags that parse the body section of the tag using
# a Ruby parser.
#
# It provides a `tag_pattern` declarative method that is used to specify a pattern of
# tokens to match, and a block for handling tag instances that match the pattern.
#
#    class Inversion::Template::MyTag < Inversion::Template::CodeTag
#
#        # Match a tag that looks like: <?my "string of stuff" ?>
#        tag_pattern 'tstring_beg $(tstring_content) tstring_end' do |tag, match|
#            tag.string = match.string( 1 )
#        end
#
#    end
#
# The tokens in the `tag_pattern` are Ruby token names used by the parser. If you're creating
# your own tag, you can dump the tokens for a particular snippet using the 'inversion'
# command-line tool that comes with the gem:
#
#   $ inversion tagtokens 'attr.dump! {|thing| thing.length }'
#   ident<"attr"> period<"."> ident<"dump!"> sp<" "> lbrace<"{"> op<"|"> \
#     ident<"thing"> op<"|"> sp<" "> ident<"thing"> period<".">          \
#     ident<"length"> sp<" "> rbrace<"}">
#
# :TODO: Finish the tag_pattern docs: placeholders, regex limitations, etc.
#
class Inversion::Template::CodeTag < Inversion::Template::Tag
	include Inversion::AbstractClass


	class TokenPattern < Ripper::TokenPattern
		extend Loggability

		# Loggability API -- use Inversion's logger
		log_to :inversion

		# Expose the source attribute
		attr_reader :source


		### Overloaded to generate a bound regex.
		def compile( pattern )
			self.log.debug "Compiling token pattern from: %p" % [ pattern ]

			if m = /[^\w\s$()\[\]{}?*+\.]/.match( pattern )
				raise Ripper::TokenPattern::CompileError, "invalid char in pattern: #{m[0].inspect}"
			end

			buf = +'\\A'
			pattern.scan(/(?:\w+|\$\(|[()\[\]\{\}?*+\.]+)/) do |tok|
				case tok
				when /\w/
					buf.concat( map_token(tok) )
				when '$('
					buf.concat( '(' )
				when '('
					buf.concat( '(?:' )
				when /[?*\[\])\.]/
					buf.concat( tok )
				else
					raise 'must not happen'
				end
			end
			buf.concat( '\z' )

			self.log.debug "  resulting token pattern is: %p" % [ buf ]
			return Regexp.compile( buf )

		rescue RegexpError => err
			raise Ripper::TokenPattern::CompileError, err.message
		end


	end # class TokenPattern



	#################################################################
	###	C L A S S   M E T H O D S
	#################################################################

	### Return the tag patterns for this class, or those of its superclass
	### if it doesn't override them.
	def self::tag_patterns
		return @tag_patterns if defined?( @tag_patterns )
		return self.superclass.tag_patterns
	end


	### Declare a `token_pattern` for tag bodies along with a `callback` that will
	### be called when a tag matching the pattern is instantiated. The `callback` will
	### be called with the tag instance, and the MatchData object that resulted from
	### matching the input, and should set up the yielded `tag` object appropriately.
	def self::tag_pattern( token_pattern, &callback ) #:yield: tag, match_data
		pattern = TokenPattern.compile( token_pattern )
		@tag_patterns = [] unless defined?( @tag_patterns )
		@tag_patterns << [ pattern, callback ]
	end


	### Declarative that forces a tag to inherit existing patterns from
	### its parent, rather than replacing them.  Afterwards, you can use
	### `tag_pattern` regularly, appending to the list.
	def self::inherit_tag_patterns
		raise ScriptError, "Patterns already exist for this tag." if defined?( @tag_patterns )
		@tag_patterns = self.superclass.tag_patterns
	end


	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Initialize a new tag that expects Ruby code in its `body`. Calls the
	### tag's #parse_pi_body method with the specified `body`.
	def initialize( body, linenum=nil, colnum=nil ) # :notnew:
		super

		@body = body.strip
		@identifiers = []
		@matched_pattern = self.match_tag_pattern( body )
	end


	######
	public
	######

	# the body of the tag
	attr_reader :body

	# the identifiers in the code contained in the tag
	attr_reader :identifiers


	### Render the node as text.
	pure_virtual :render



	#########
	protected
	#########

	### Match the given `body` against one of the tag's tag patterns, calling the
	### block associated with the first one that matches and returning the matching
	### pattern.
	def match_tag_pattern( body )

		self.class.tag_patterns.each do |tp, callback|
			self.log.debug "Testing for a match against %p" % [ tp ]
			if match = tp.match( body.strip )
				self.log.debug "Matched tag pattern: %p, match is: %p" % [ tp, match ]
				callback.call( self, match )
				return tp
			end
		end

		self.log.error "Failed to match %p with %d patterns." %
			[ body, self.class.tag_patterns.length ]

		valid_patterns = self.class.tag_patterns.map( &:first ).map( &:source ).join( "\n  ")
		tokenized_src = Ripper.lex( body ).collect do |tok|
			self.log.debug "  lexed token: #{tok.inspect}"
			"%s<%s>" % [ tok[1].to_s[3..-1], tok[2] ]
		end.join(' ')

		raise Inversion::ParseError, "malformed %s: expected one of:\n  %s\ngot:\n  %s" %
			[ self.tagname, valid_patterns, tokenized_src ]
	end

end # class Inversion::Template::CodeTag

