#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/node'

# Inversion template textnode base class.
class Inversion::Template::TextNode < Inversion::Template::Node
	include Inversion::Loggable

	### Create a new TextNode with the specified +source+.
	### @param [String] source  the text source to wrap in the node object
	### @param [Integer] linenum the line number the node was parsed from
	### @param [Integer] colnum  the column number the node was parsed from
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
	### @return [String]  the rendered text
	def render( renderstate )
		body = self.body.dup
		body.sub!( /\A\r?\n/, '' ) if renderstate && renderstate.options[:strip_tag_lines]

		return body
	end


	### Render the text node as the body of a comment.
	### @return [String]
	def as_comment_body
		comment_body = self.body[0,40].dump
		comment_body[-1,0] = '...' unless comment_body == self.body.dump
		return "Text (%d bytes): %s" % [ self.body.length, comment_body ]
	end

end # class Inversion::Template::TextNode

