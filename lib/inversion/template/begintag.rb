#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/mixins'
require 'inversion/template/attrtag'
require 'inversion/template/containertag'
require 'inversion/template/rescuetag'


# Inversion 'begin' tag.
#
# This tag causes a section of the template to be rendered only if no exceptions are raised
# while it's being rendered. If an exception is raised, it is checked against any 'rescue'
# blocks, and the first one with a matching exception is rendered instead. If no 'rescue' block
# is found, the exception is handled by the configured exception behavior for the template,
# and the resulting replaces the block.
#
# == Syntax
#
#   <?begin ?><?call employees.length ?><?end?>
#
#   <?begin ?>
#       <?for employee in employees.all ?>
#           <?attr employee.name ?> --> <?attr employee.title ?>
#       <?end for?>
#   <?rescue DatabaseError => err ?>
#       Oh no!! I can't talk to the database for some reason.  The
#       error was as follows:
#       <pre>
#           <?attr err.message ?>
#       </pre>
#   <?end?>
#
class Inversion::Template::BeginTag < Inversion::Template::Tag
	include Inversion::Template::ContainerTag


	### Initialize a new BeginTag.
	def initialize( body='', linenum=nil, colnum=nil ) # :notnew:
		super
		@rescue_clauses = [] # [ [RuntimeError, ArgumentError], [subnodes] ]
	end


	######
	public
	######

	# The tuples of rescue clauses handled by the begin
	attr_reader :rescue_clauses


	### Override the append operator to separate out RescueTags and the nodes that follow
	### them.
	def <<( subnode )
		case

		# If this node is a <?rescue?>, add a container for the subnodes that belong to it
		# and the list of exception types that it rescues
		when subnode.is_a?( Inversion::Template::RescueTag )
			@rescue_clauses << [ subnode.exception_types, [] ]

		# If there's already at least one rescue clause in effect, add any subnodes to
		# the last one
		when !@rescue_clauses.empty?
			@rescue_clauses.last[1] << subnode

		# Append nodes in the begin, but before any rescue to the begin tag
		else
			super
		end

		return self
	end


	### Render the tag's contents if the condition is true, or any else or elsif sections
	### if the condition isn't true.
	def render( state )
		output = []

		errhandler = self.method( :handle_exception )
		state.with_destination( output ) do
			state.with_error_handler( errhandler ) do
				catch( :stop_rendering ) do
					super
				end
				self.log.debug "  leaving the error-handler block"
			end
			self.log.debug "  leaving the overridden output block"
		end

		self.log.debug "Rendered begin section as: %p" % [ output ]
		return output
	end


	### The replacement exception-handler provided to RenderState.
	def handle_exception( state, node, exception )
		self.log.debug "Handling %p raised by %p: %s" % [ exception.class, node, exception.message ]
		state.destination.clear

		self.rescue_clauses.each do |errclasses, nodes|
			self.log.debug "  considering rescue clause: %p -> %p" % [ errclasses, nodes ]
			if errclasses.any? {|eclass| eclass === exception }
				self.log.debug "  rescued by a clause for %p" % [ errclasses ]
				nodes.each {|innernode| state << innernode }
				throw :stop_rendering
			end
		end

		# Use the default error handler
		self.log.debug "  no rescue clause for a %p: falling back to the default error handler" %
			[ exception.class ]
		state.destination << state.default_error_handler( state, node, exception )
		throw :stop_rendering
	end

end # class Inversion::Template::BeginTag

