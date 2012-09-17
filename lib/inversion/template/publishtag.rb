#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/tag'
require 'inversion/template/containertag'

# Inversion publish tag.
#
# The publish tag exports one or more subnodes to enclosing templates.
#
# == Syntax
#
#   <!-- Outer template -->
#   <html>
#     <head>
#       <?subscribe headers ?>
#     </head>
#     <body><?attr body ?></body>
#   </html>
#
#   <!-- In the body template, add a stylesheet link to the outer
#        template's <head> -->
#   <?publish headers ?>
#      <link rel="stylesheet" ... />
#   <?end ?>
#   <div>(page content)</div>
#
class Inversion::Template::PublishTag < Inversion::Template::Tag
	include Inversion::Template::ContainerTag


	### Create a new PublishTag with the given +body+.
	def initialize( body, line=nil, column=nil )
		super

		key = self.body[ /^([a-z]\w+)$/ ] or
			raise Inversion::ParseError,
				"malformed key: expected simple identifier, got %p" % [ self.body ]
		@key = key.to_sym
	end


	######
	public
	######

	# The name of the key the nodes will be published under
	attr_reader :key


	### Render the published subnodes in the context of the given +renderstate+, but
	### save them for publication after the render is done.
	def render( renderstate )
		self.log.debug "Publishing %d nodes as %s" % [ self.subnodes.length, self.key ]
		rendered_nodes = []
		renderstate.with_destination( rendered_nodes ) do
			sn = self.render_subnodes( renderstate )
			self.log.debug "  subnodes are: %p" % [ sn ]
			sn
		end

		self.log.debug "  rendered nodes are: %p" % [ rendered_nodes ]
		renderstate.publish( self.key, *rendered_nodes ) unless rendered_nodes.empty?

		return nil
	end


	### Render the tag as the body of a comment, suitable for template debugging.
	def as_comment_body
		return "Published %d nodes as %s" % [ self.subnodes.length, self.key ]
	end

end # class Inversion::Template::PublishTag

