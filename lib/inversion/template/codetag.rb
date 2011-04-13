#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'ripper'
require 'inversion/template/tag'

### FIXME: Top-level docs
###
class Inversion::Template::CodeTag < Inversion::Template::Tag
	include Inversion::Loggable,
	        Inversion::AbstractClass


	### A subclass of Ripper::TokenPattern that binds matches to the beginning and
	### end of the matched string.
	class TokenPattern < Ripper::TokenPattern

		# @return [String]  the token pattern's source string
		attr_reader :source

		#########
		protected
		#########

		### Compile the token pattern into a Regexp
		### @param [String] pattern  the token pattern to compile
		### @return [Regexp]
		def compile( pattern )
			if m = /[^\w\s$()\[\]{}?*+\.]/.match( pattern )
				raise Ripper::TokenPattern::CompileError,
					"invalid char in pattern: #{m[0].inspect}"
			end

			buf = '^'
			pattern.scan( /(?:\w+|\$\(|[()\[\]\{\}?*+\.]+)/ ) do |tok|
				case tok
				when /\w/
					buf << map_token( tok )
				when '$('
					buf << '('
				when '('
					buf << '(?:'
				when /[?*\[\])\.]/
					buf << tok
				else
					raise ScriptError, "invalid token in pattern: %p" % [ tok ]
				end
			end
			buf << '$'

			Regexp.compile( buf )
		rescue RegexpError => err
			raise Ripper::TokenPattern::CompileError, err.message
		end

	end # class TokenPattern


	#################################################################
	###	C L A S S   M E T H O D S
	#################################################################

	class << self
		attr_accessor :tag_patterns
	end


	### Inheritance hook -- set the subclass's tag patterns.
	def self::inherited( subclass )
		super
		subclass.tag_patterns = []
	end


	### Declare a +token_pattern+ for tag bodies along with a +callback+ that will
	### be called when a tag matching the pattern is instantiated.
	### @param [String] token_pattern  the Ripper token pattern to use for matching the tag body
	### @param [Proc, #to_proc] callback  the block to call when the tag is instantiated
	def self::tag_pattern( token_pattern, &callback )
		pattern = TokenPattern.compile( token_pattern )
		self.tag_patterns << [ pattern, callback ]
	end


	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Initialize a new tag that expects Ruby code in its +body+. Calls the
	### tag's #parse_pi_body method with the specified +body+.
	### @param [String] body  the Ruby source of the tag body
	def initialize( body ) # :notnew:
		super

		@body = body.strip
		@identifiers = []
		@matched_pattern = self.match_tag_pattern( body )
	end


	######
	public
	######

	# @return [String] the body of the tag
	attr_reader :body

	# @return [Array<Symbol>] the identifiers in the code contained in the tag
	attr_reader :identifiers


	### Render the node as text.
	### @return [String] the rendered node
	pure_virtual :render



	#########
	protected
	#########

	### Match the given +body+ against one of the tag's tag patterns, calling the
	### block associated with the first one that matches and returning the matching
	### pattern.
	### @param [String] body  the body of the tag
	### @return [Inversion::Template::CodeTag::TokenPattern] the matching pattern
	def match_tag_pattern( body )

		self.class.tag_patterns.each do |tp, callback|
			if match = tp.match( body.strip )
				self.log.debug "Matched tag pattern: %p" % [ tp ]
				callback.call( self, match )
				return tp
			end
		end

		self.log.error "Failed to match %p with %d patterns." %
			[ body, self.class.tag_patterns.length ]

		valid_patterns = self.class.tag_patterns.map( &:first ).map( &:source ).join( "\n  ")
		tokenized_src = Ripper.lex( body ).collect do |tok|
			"%s<%s>" % [ tok[1][3..-1], tok[2] ]
		end.join(' ')

		raise Inversion::ParseError, "malformed %s: expected one of:\n  %s\ngot:\n  %s" %
			[ self.class.name.sub(/.*::/, ''), valid_patterns, tokenized_src ]
	end

end # class Inversion::Template::CodeTag

