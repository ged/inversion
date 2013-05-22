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

	### Overridden to default body to nothing, and raise an error if it has one.
	def initialize( body='', linenum=nil, colnum=nil ) # :notnew:
		raise Inversion::ParseError, "else can't have a condition" unless body.to_s.strip == ''
		super
	end


	######
	public
	######


	### Parsing callback -- check to be sure the node tree can have an
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


	### Always remder as an empty string.
	def render( * )
		nil
	end


	### Toggle rendering for the iftag's container if rendering hasn't yet been
	### toggled.
	def before_rendering( renderstate )
		if renderstate.tag_data[ :rendering_was_enabled ]
			self.log.debug "  rendering was previously enabled: disabling"
			renderstate.disable_rendering
		else
			self.log.debug "  rendering was previously disabled: enabling"
			renderstate.tag_data[ :rendering_was_enabled ] = true
			renderstate.enable_rendering
		end

		return nil
	end

end # class Inversion::Template::ElseTag

