#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/tag'


# Inversion 'else' tag.
#
# This tag adds a logical switch to an IfTag. If the IfTag's condition was false, 
# start rendering.
#
# == Syntax
#
#   <?if attr ?>
#       ...
#   <?else ?>
#       ...
#   <?end?>
#
class Inversion::Template::ElseTag < Inversion::Template::Tag
	include Inversion::Loggable


	### Overridden to default body to nothing, and raise an error if it has one.
	def initialize( body='', linenum=nil, colnum=nil ) # :notnew:
		raise Inversion::ParseError, "else can't have a condition" unless body.to_s.strip == ''
		super
	end


	######
	public
	######


	### Parsing callback -- check to be sure the node tree can have the
	### 'else' tag appended to it.
	def before_appending( parsestate )
		condtag = parsestate.node_stack.reverse.find do |node|
			case node

			# If there was a previous 'if' or 'unless', the else belongs to it. Also
			# allow it to be appended to a 'comment' section so you can comment out an 
			# else clause
			when Inversion::Template::IfTag,
			     Inversion::Template::UnlessTag,
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

end # class Inversion::Template::RescueTag

