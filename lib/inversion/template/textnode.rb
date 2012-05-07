#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/node'

# Inversion text node class -- container for static content in templates between tags.
class Inversion::Template::TextNode < Inversion::Template::Node

	### Create a new TextNode with the specified +source+.
	def initialize( body, linenum=nil, colnum=nil )
		@body = body
		super
	end


	######
	public
	######

	# The node body
	attr_reader :body


	### Render the node.
	def render( renderstate )
		body = self.body.dup
		body.sub!( /\A\r?\n/, '' ) if renderstate && renderstate.options[:strip_tag_lines]

		return body
	end


	### Render the text node as the body of a comment.
	def as_comment_body
		comment_body = self.body[0,40].dump
		comment_body[-1,0] = '...' unless comment_body == self.body.dump
		return "Text (%d bytes): %s" % [ self.body.length, comment_body ]
	end

end # class Inversion::Template::TextNode

