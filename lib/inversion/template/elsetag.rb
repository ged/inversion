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
		raise Inversion::ParseError, "else can't have a condition" unless body.strip == ''
		super
	end


	######
	public
	######


	### Parsing callback -- check to be sure the node tree can have the
	### 'else' tag appended to it.
	def before_append( parsestate )
		condtag = parsestate.node_stack.reverse.find do |node|
			case node
			when Inversion::Template::IfTag,
			     Inversion::Template::UnlessTag,
			     Inversion::Template::CommentTag
				break node
			when Inversion::Template::ContainerTag
				raise Inversion::ParseError, "'%s' tags can't have '%s' clauses at %s" %
					[ node.tagname.downcase, self.tagname.downcase, self.location ]
			end
		end

		unless condtag
			raise Inversion::ParseError, "orphaned '%s' tag at %s" %
				[ self.tagname.downcase, self.location ]
		end
	end


	### Render the tag as the body of a comment, suitable for template 
	### debugging.
	### @return [String]  the tag as the body of a comment
	# def as_comment_body
	# end

end # class Inversion::Template::ElseTag

