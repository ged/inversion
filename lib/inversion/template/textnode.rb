#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/node'

# Inversion template tag base class.
class Inversion::Template::TextNode < Inversion::Template::Node

	### Create a new TextNode with the specified +source+.
	### @param [String] source  the text source to wrap in the node object
	def initialize( source )
		@source = source
		super()
	end


	######
	public
	######

	# The node source
	attr_reader :source


	### Render the node.
	### @return [String]  the rendered text
	def render
		return @source.dup
	end

end # class Inversion::Template::TextNode

