#!/usr/bin/env ruby
# encoding: utf-8
# vim: set noet nosta sw=4 ts=4 :

require 'loggability'

require 'inversion/template' unless defined?( Inversion::Template )
require 'inversion/mixins'
require 'inversion/template/textnode'
require 'inversion/template/tag'
require 'inversion/template/endtag'

# This is the parser for Inversion templates. It takes template source and
# returns a tree of Inversion::Template::Node objects (if parsing is successful).
class Inversion::Parser
	extend Loggability

	# Loggability API -- set up logging through the Inversion module's logger
	log_to :inversion


	# The pattern for matching a tag opening
	TAG_OPEN = /[\[<]\?/

	# The pattern for matching a tag.
	TAG_PATTERN = %r{
		(?<tagstart>#{TAG_OPEN})    # Tag opening: either <? or [?
		(?<tagname>[a-z]\w*)        # The name of the tag
		(?:\s+                      # At least once whitespace character between the tagname and body
		    (?<body>.+?)            # The body of the tag
		)?
		\s*
		(?<tagend>\?[\]>])          # Tag closing: either ?] or ?>
	}x

	# Valid tagends by tagstart
	MATCHING_BRACKETS = {
		'<?' => '?>',
		'[?' => '?]',
	}

	# Default values for parser configuration options.
	DEFAULT_OPTIONS = {
		:ignore_unknown_tags => true,
	}


	### Create a new Inversion::Parser with the specified config +options+.
	def initialize( template, options={} )
		@template = template
		@options  = DEFAULT_OPTIONS.merge( options )
	end


	######
	public
	######

	# The parser's config options
	attr_reader :options


	### Parse the given +source+ into one or more Inversion::Template::Nodes and return
	### it as an Array.
	def parse( source, inherited_state=nil )
		state = nil

		if inherited_state
			inherited_state.template = @template
			state = inherited_state
		else
			state = Inversion::Parser::State.new( @template, self.options )
		end

		self.log.debug "Starting parse of template source (%0.2fK, %s)" %
			[ source.bytesize/1024.0, source.encoding ]

		t0 = Time.now
		last_pos = last_linenum = last_colnum = 0
		source.scan( TAG_PATTERN ) do |*|
			match = Regexp.last_match
			start_pos, end_pos = match.offset( 0 )
			linenum            = match.pre_match.count( "\n" ) + 1
			colnum             = match.pre_match.length - (match.pre_match.rindex("\n") || -1)

			# Error on <?...?] and vice-versa.
			unless match[:tagend] == MATCHING_BRACKETS[match[:tagstart]]
				raise Inversion::ParseError,
					"malformed tag %p: mismatched start and end brackets at line %d, column %d" %
					[ match[0], linenum, colnum ]
			end

			# Check for nested tags
			if match[0].index( TAG_OPEN, 2 )
				raise Inversion::ParseError, "unclosed or nested tag %p at line %d, column %d" %
					[ match[0], linenum, colnum ]
			end

			# self.log.debug "  found a tag at offset: %d (%p) (line %d, col %d)" %
			#     [ start_pos, abbrevstring(match[0]), linenum, colnum ]

			# If there were characters between the end of the last match and
			# the beginning of the tag, create a text node with them
			unless last_pos == start_pos
				text = match.pre_match[ last_pos..-1 ]
				# self.log.debug "  adding literal text node: %p" % [ abbrevstring(text) ]
				state << Inversion::Template::TextNode.new( text, last_linenum, last_colnum )
			end

			# self.log.debug "  creating tag with tagname: %p, body: %p" %
			#    [ match[:tagname], match[:body] ]

			tag = Inversion::Template::Tag.create( match[:tagname], match[:body], linenum, colnum )
			if tag.nil?
				unless state.options[ :ignore_unknown_tags ]
					raise Inversion::ParseError, "Unknown tag %p at line %d, column %d" %
						[ match[:tagname], linenum, colnum ]
				end

			    tag = Inversion::Template::TextNode.new( match[0], linenum, colnum )
			end

			# self.log.debug "  created tag: %p" % [ tag ]
			state << tag

			# Keep offsets for the next match
			last_pos     = end_pos
			last_linenum = linenum + match[0].count( "\n" )
			last_colnum  = match[0].length - ( match[0].rindex("\n") || -1 )
		end

		# If there are any characters left over after the last tag
		remainder = source[ last_pos..-1 ]
		if remainder && !remainder.empty?
			# self.log.debug "Remainder after last tag: %p" % [ abbrevstring(remainder) ]

			# Detect unclosed tags
			if remainder.index( "<?" ) || remainder.index( "[?" )
				raise Inversion::ParseError,
					"unclosed tag after line %d, column %d" % [ last_linenum, last_colnum ]
			end

			# Add any remaining text as a text node
			state << Inversion::Template::TextNode.new( remainder, last_linenum, last_colnum )
		end
		self.log.debug "  done parsing: %0.5fs" % [ Time.now - t0 ]

		return state.tree
	end


	#######
	private
	#######

	### Return at most +length+ characters long from the given +string+, appending +ellipsis+
	### at the end if it was truncated.
	def abbrevstring( string, length=30, ellipsis='…' )
		return string if string.length < length
		length -= ellipsis.length
		return string[ 0, length ] + ellipsis
	end


	# Parse state object class. State objects keep track of where in the parse tree
	# new nodes should be appended, and manages inclusion.
	class State
		extend Loggability

		# Write logs to the Inversion logger
		log_to :inversion

		### Create a new State object
		def initialize( template, options={} )
			@template      = template
			@options       = options.dup
			@tree          = []
			@node_stack    = [ @tree ]
			@include_stack = []
		end


		### Copy constructor -- duplicate inner structures.
		def initialize_copy( original )
			@template      = original.template
			@options       = original.options.dup
			@tree          = @tree.map( &:dup )
			@node_stack    = [ @tree ]
			@include_stack = original.include_stack.dup
		end


		######
		public
		######

		# The parse options in effect for this parse state
		attr_reader :options

		# The template object for this parser state
		attr_accessor :template

		# The stack of templates that have been loaded for this state; for loop detection.
		attr_reader :include_stack

		# The stack of containers
		attr_reader :node_stack


		### Append operator: add nodes to the correct part of the parse tree.
		def <<( node )
			# self.log.debug "Appending %p" % [ node ]

			node.before_appending( self )
			self.node_stack.last << node

			if node.is_container?
				# Containers get pushed onto the stack so they get appended to
				self.node_stack.push( node )
			else
				# Container nodes' #after_appending gets called in #pop
				node.after_appending( self )
			end

			return self
		rescue Inversion::ParseError => err
			raise err, "%s at %s" % [ err.message, node.location ]
		end


		### Append another Array of nodes onto this state's node tree.
		def append_tree( newtree )
			newtree.each do |node|
				self.node_stack.last << node
			end
		end


		### Returns the tree if it's well formed.
		def tree
			unless self.is_well_formed?
				raise Inversion::ParseError, "Unclosed container tag: %s, from %s" %
					[ self.node_stack.last.tagname, self.node_stack.last.location ]
			end
			return @tree
		end


		### Check to see if all open tags have been closed.
		def is_well_formed?
			return self.node_stack.length == 1
		end
		alias_method :well_formed?, :is_well_formed?


		### Pop one level off of the node stack and return it.
		def pop
			closed_node = self.node_stack.pop

			# If there's nothing on the node stack, we've popped the top-level
			# Array, which means there wasn't an opening container.
			raise Inversion::ParseError, "unbalanced end: no open tag" if
				self.node_stack.empty?

			closed_node.after_appending( self )

			return closed_node
		end


		### Return the node that is currently being appended to, or +nil+ if there aren't any
		### opened container nodes.
		def current_node
			return self.node_stack.last
		end


		### Clear any parsed nodes from the state, leaving the options and include_stack intact.
		def clear_nodes
			@tree       = []
			@node_stack = [ @tree ]
		end


		### Load a subtemplate from the specified +path+, checking for recursive-dependency.
		def load_subtemplate( path )
			if self.include_stack.include?( path )
				stack_desc = ( self.include_stack + [path] ).join( ' --> ' )
				msg = "Recursive load of %p detected: from %s" % [ path, stack_desc ]

				self.log.error( msg )
				raise Inversion::StackError, msg
			end

			# self.log.debug "Include stack is: %p" % [ self.include_stack ]

			substate = self.dup
			substate.clear_nodes
			substate.include_stack.push( path )

			return Inversion::Template.load( path, substate, self.options )
		end

	end # class Inversion::Parser::State

end # class Inversion::Parser


