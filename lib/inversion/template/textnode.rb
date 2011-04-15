#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/node'

# Inversion template tag base class.
class Inversion::Template::TextNode < Inversion::Template::Node

	### Create a new TextNode with the specified +source+.
	### @param [String] source  the text source to wrap in the node object
	def initialize( body )
		@body = body
		super()
	end


	######
	public
	######

	# The node body
	attr_reader :body


	### Render the node.
	### @return [String]  the rendered text
	def render( unused=nil )
		return @body.dup
	end

end # class Inversion::Template::TextNode

