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

	# Default values for parser configuration options.
	DEFAULT_OPTIONS = {
		:raise_on_unknown => false,
	}


	### Create a new Inversion::Template::Parser with the specified config +options+.
	### @param [Hash] options  configuration options that override DEFAULT_OPTIONS
	def initialize( options={} )
		@options = DEFAULT_OPTIONS.merge( options )
	end


	######
	public
	######

	# The parser's config options
	attr_reader :options


	### Parse the given +source+ into one or more Inversion::Template::Nodes and return 
	### it as an Array.
	### @param [String] source  the template source
	### @return [Array<Inversion::Template::Node>]  the nodes parsed from the +source+.
	def parse( source )
		tree = []

		scanner = StringScanner.new( source )
		self.log.debug "Starting parse of template source (%0.2fK" % [ source.length/1024.0 ]
		until scanner.eos?
			startpos = scanner.pos
			self.log.debug "  scanning from offset: %d" % [ startpos ]

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
				tagclose = tagopen.reverse.tr( '<[', '>]' )
				tagclose_re = Regexp.new( Regexp.escape(tagclose) )
				self.log.debug "  looking for tag close: %p" % [ tagclose ]

				# Handle unclosed tags
				unless scanner.skip_until( tagclose_re )
					raise Inversion::ParseError, "Unable to locate closing tag"
				end

				tagcontent = scanner.string[ tagstart..(scanner.pos - 3) ]
				tag, body = tagcontent.split( /\s+/, 2 )
				self.log.debug "  found tag: %p, body %p" % [ tag, body ]

				tag = Inversion::Template::Tag.create( tag, body )
				if tag.nil?
					raise Inversion::ParseError, "Unknown tag %p" % [ body ] if
						self.options[ :raise_on_unknown ]
				    tag = Inversion::Template::TextNode.new( tagopen + tagcontent + tagclose )
				end

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


