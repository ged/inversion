#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/attrtag'
require 'inversion/template/iftag'
require 'inversion/template/commenttag'


# Inversion 'elsif' tag.
#
# This tag adds a conditional logical switch to an IfTag. If the IfTag's condition was false, 
# but the attribute or methodchain of the elsif is true, start rendering.
#
# == Syntax
#
#   <?if attr ?>
#       ...
#   <?elsif attr ?>
#       ...
#   <?elsif attr.methodchain ?>
#       ...
#   <?end?>
#
class Inversion::Template::ElsifTag < Inversion::Template::AttrTag
	include Inversion::Loggable

	# Inherits AttrTag's tag patterns

	### Parsing callback -- check to be sure the node tree can have an
	### 'elsif' tag appended to it (i.e., it has an opening 'if' tag).
	def before_appending( parsestate )
		condtag = parsestate.node_stack.reverse.find do |node|
			case node
			when Inversion::Template::IfTag,
			     Inversion::Template::CommentTag
				break node
			when Inversion::Template::ContainerTag
				raise Inversion::ParseError, "'%s' tags can't have '%s' clauses" %
					[ node.tagname.downcase, self.tagname.downcase ]
			end
		end

		unless condtag
			raise Inversion::ParseError, "orphaned '%s' tag" % [ self.tagname.downcase ]
		end
	end

end # class Inversion::Template::ElsifTag

