#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/tag'
require 'inversion/template/containertag'


# Inversion 'comment' tag.
#
# This tag hides its contents from the rendered output.
#
# == Syntax
#
#   <?comment ?><?end?>
#   <?comment Disabled for now ?>
#      <?attr some_hidden_attribute ?>
#   <?end comment ?>
#
class Inversion::Template::CommentTag < Inversion::Template::Tag
	include Inversion::Template::ContainerTag


	######
	public
	######

	### Render (or don't render, actually) the comment's subnodes.
	def render( state )
		return ''
	end


	### Render the tag as the body of a comment, suitable for template
	### debugging.
	def as_comment_body
		firstnode, lastnode = self.subnodes.first, self.subnodes.last
		nodecount = self.subnodes.length

		linedesc = if firstnode.linenum == lastnode.linenum
				"on line %d" % [ firstnode.linenum ]
			else
				"from line %d to %d" % [ firstnode.linenum, lastnode.linenum ]
			end

		return "Commented out %d nodes %s%s" % [
			nodecount,
			linedesc,
			self.body.empty? ? '' : ': ' + self.body,
		]

	end

end # class Inversion::Template::CommentTag

