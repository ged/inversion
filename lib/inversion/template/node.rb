#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/mixins'
require 'inversion/template' unless defined?( Inversion::Template )

# Inversion template node base class
class Inversion::Template::Node
	include Inversion::AbstractClass


	### Render the node in the given +template+. By default, rendering a node 
	### returns the empty string.
	def render( template=nil )
		return ''
	end


	### Render the node as a comment 
	def as_comment_body
		return self.inspect
	end

end # class Inversion::Template::Node

