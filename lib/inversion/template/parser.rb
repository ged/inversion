#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'strscan'

require 'inversion/template' unless defined?( Inversion::Template )
require 'inversion/mixins'
require 'inversion/template/textnode'
require 'inversion/template/tag'

# This is the parser for Inversion templates. It takes template source and
# returns a tree of Inversion::Template::Node objects (if parsing is successful).
#
# @author Michael Granger <ged@FaerieMUD.org>
# @author Mahlon E. Smith <mahlon@martini.nu>
#
class Inversion::Template::Parser
	include Inversion::Loggable

	# The pattern for matching the beginning of a tag.
	TAG_START = /[<\[]\?/


	### Parse the given +source+ and return a
	def parse( source )
		tree = []

		scanner = StringScanner.new( source )

		until scanner.eos?
			startpos = scanner.pos

			# Scan for the next directive. When the scanner reaches
			# the end of the parsed string, just append any plain
			# text that's left and stop scanning.
			if scanner.skip_until( TAG_START )
				tagstart = scanner.pos
				self.log.debug "  tag start position is (%d) %p" % [ tagstart, scanner.rest ]

				# Add the literal String node leading up to the tag
				# as a text node.
				unless ( scanner.pre_match == '' )
					self.log.debug "  adding literal text node '%s...'" % [ scanner.pre_match[0,20] ]
					tree << Inversion::Template::TextNode.new( scanner.pre_match )
				end

				# Look for the end of the tag based on what its opening characters were
				tagopen  = scanner.matched
				tagclose = Regexp.new( Regexp.escape( tagopen.reverse.tr('<[', '>]') ))
				self.log.debug "  looking for tag close: %p" % [ tagclose ]

				# Handle unclosed tags
				unless scanner.skip_until( tagclose )
					raise Inversion::ParseError, "Unable to locate closing tag"
				end

				tag, body = scanner.string[ tagstart..(scanner.pos - 3) ].split( /\s+/, 2 )
				self.log.debug "  found tag: %p, body %p" % [ tag, body ]
				tag = Inversion::Template::Tag.create( tag, body )
				self.log.debug "  created tag node: %p" % [ tag ]
				tree << tag
			else
				self.log.debug "  adding a text node for the rest of the template"
				tree << Inversion::Template::TextNode.new( scanner.rest )
				self.log.debug "  finished parsing."
				scanner.terminate
			end
		end

		return tree
	end



end # class Inversion::Template::Parser


