#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/tag'


# Inversion 'rescue' tag.
#
# This tag adds a logical switch to a BeginTag. If rendering any of the BeginTag's nodes raises
# an exception of the type specified by the RescueTag, the nodes following the RescueTag are
# rendered instead.
#
# == Syntax
#
#   <?begin ?>
#       <?for employee in employees.all ?>
#           <?attr employee.name ?> --> <?attr employee.title ?>
#       <?end for?>
#   <?rescue DatabaseError => err ?>
#       Oh no!! I can't talk to the database for some reason.  The
#       error was as follows:
#
#           <?attr err.message ?>
#
#   <?end?>
#
class Inversion::Template::RescueTag < Inversion::Template::Tag

	### Overridden to default body to nothing, and raise an error if it has one.
	def initialize( body='', linenum=nil, colnum=nil ) # :notnew:
		super
		@exception_types = parse_exception_types( self.body )
	end


	######
	public
	######

	# The exception classes the rescue will handle (an Array of Class objects)
	attr_reader :exception_types


	### Parsing callback -- check to be sure the node tree can have the
	### 'rescue' tag appended to it.
	def before_appending( parsestate )
		condtag = parsestate.node_stack.reverse.find do |node|
			case node

			# If there was a previous 'begin', the 'rescue' belongs to it. Also
			# allow it to be appended to a 'comment' section so you can comment out a
			# rescue clause without commenting out the begin
			when Inversion::Template::BeginTag,
			     Inversion::Template::CommentTag
				break node

			# If it's some other kind of container, it's an error
			when Inversion::Template::ContainerTag
				raise Inversion::ParseError, "'%s' tags can't have '%s' clauses" %
					[ node.tagname.downcase, self.tagname.downcase ]
			end
		end

		# If there wasn't a valid container, it's an error too
		raise Inversion::ParseError, "orphaned '%s' tag" % [ self.tagname.downcase ] unless condtag
	end


	#######
	private
	#######

	### Parse one or more exception classes from the given +rescuespec+ and return them.
	def parse_exception_types( rescuespec )
		return [ ::RuntimeError ] if rescuespec.nil? || rescuespec == ''

		# Turn a comma-delimited list of exception names into the corresponding classes
		return rescuespec.split( /\s*,\s*/ ).collect do |classname|
			classname.split( '::' ).
				reject( &:empty? ).
				inject( Object ) do |klass, name|
					klass = klass.const_get( name ) or
						raise "No such exception class %s" % [ classname ]
						klass
				end
		end
	end

end # class Inversion::Template::RescueTag

