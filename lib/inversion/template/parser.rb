#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'strscan'

require 'inversion/template' unless defined?( Inversion::Template )
require 'inversion/mixins'
require 'inversion/template/textnode'
require 'inversion/template/tag'
require 'inversion/template/endtag'

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
		state = State.new

		scanner = StringScanner.new( source )
		self.log.debug "Starting parse of template source (%0.2fK)" % [ source.length/1024.0 ]
		until scanner.eos?
			startpos = scanner.pos
			self.log.debug "  scanning from offset: %d" % [ startpos ]

			# Scan for the next directive. When the scanner reaches
			# the end of the parsed string, just append any plain
			# text that's left and stop scanning.
			if scanner.skip_until( TAG_START )
				tagstart     = scanner.pos - scanner.matched.length
				tagbodystart = scanner.pos
				linenum      = scanner.pre_match.count( "\n" ) + 1
				line_start   = scanner.pre_match.rindex( "\n" ) || 0
				colnum       = scanner.pre_match.length - line_start - 1

				self.log.debug "  tag start position is (%d) %p (line %d, col %d)" %
					[ tagstart, scanner.rest, linenum, colnum ]

				# If there were characters between the starting position and
				# the beginning of the tag, create a text node with them
				unless tagstart == startpos
					self.log.debug "  extracting text from %d to %d" % [ startpos, tagstart ]
					# extract the string between the end of the last match, and the
					# beginning of the current match.
					text = scanner.string[ startpos..(tagstart - 1) ]
					self.log.debug "  adding literal text node '%s...'" % [ text[0,20] ]
					state << Inversion::Template::TextNode.new( text, linenum, colnum )
				end

				# Look for the end of the tag based on what its opening characters were
				tagopen     = scanner.matched
				tagclose    = tagopen.reverse.tr( '<[', '>]' )
				tagclose_re = Regexp.new( Regexp.escape(tagclose) )
				self.log.debug "  looking for tag close: %p" % [ tagclose ]

				# Handle unclosed (eof) tags
				scanner.skip_until( tagclose_re ) or
					raise Inversion::ParseError, "Unclosed tag at line %d, column %d" %
						[ linenum, colnum ]

				tagcontent = scanner.string[ tagbodystart..(scanner.pos - 3) ]
				tagname, body = tagcontent.split( /\s+/, 2 )
				self.log.debug "  found tag: %p, body %p" % [ tagname, body ]

				# Handle unclosed (nested) tags
				if body =~ TAG_START
					raise Inversion::ParseError, "Unclosed tag at line %d, column %d" %
						[ linenum, colnum ]
				end

				tag = Inversion::Template::Tag.create( tagname, body, linenum, colnum )
				if tag.nil?
					if self.options[ :raise_on_unknown ]
						raise Inversion::ParseError, "Unknown tag %p at line %d, column %d" %
							[ tagname , linenum, colnum ]
					end

					body = tagopen + tagcontent + tagclose
				    tag = Inversion::Template::TextNode.new( body, linenum, colnum )
				end

				self.log.debug "  created tag node: %p" % [ tag ]
				state << tag
			else
				self.log.debug "  adding a text node for the rest of the template"
				state << Inversion::Template::TextNode.new( scanner.rest, scanner )
				self.log.debug "  finished parsing."
				scanner.terminate
			end
		end

		return state.tree
	end



	# Parse state object class. State objects keep track of where in the parse tree
	# new nodes should be appended, and matches <?end?> tags with their openers.
	class State
		include Inversion::Loggable

		### Create a new State object
		def initialize
			@tree = []
			@node_stack = [ @tree ]
		end

		######
		public
		######


		### Append operator: add nodes to the correct part of the parse tree.
		### @param [Inversion::Template::Node] node  the parsed node
		def <<( node )
			if node.is_a?( Inversion::Template::EndTag )
				self.log.debug "End tag for %s" %
					[ node.body ? "#{node.body} tag" : "unnamed tag" ]

				closed_node = @node_stack.pop
				if @node_stack.empty?
					raise Inversion::ParseError, "unbalanced end: no open tag in stack at" % [
						node.location
					]
				end

				if node.body && node.body.downcase != closed_node.tagname.downcase
					raise Inversion::ParseError, "unbalanced end: expected %p, got %p at %s" % [
						closed_node.tagname.downcase,
						node.body.downcase,
						node.location
					]
				end
			else
				self.log.debug "Appending %p" % [ node ]
				@node_stack.last << node
				@node_stack.push( node ) if node.is_container?
			end

			self
		end


		### Returns the tree if it's well formed.
		def tree
			unless self.is_well_formed?
				raise Inversion::ParseError, "Unclosed container tag: %s, from %s" %
					[ @node_stack.last.tagname, @node_stack.last.location ]
			end
			return @tree
		end


		### Check to see if all open tags have been closed.
		def is_well_formed?
			return @node_stack.length == 1
		end
		alias_method :well_formed?, :is_well_formed?

	end # class Inversion::Template::Parser::State

end # class Inversion::Template::Parser


