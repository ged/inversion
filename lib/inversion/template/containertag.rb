#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion' unless defined?( Inversion )
require 'inversion/template' unless defined?( Inversion::Template )

# A mixin for a tag that allows it to contain other nodes.
module Inversion::Template::ContainerTag

	### Setup subnodes for including classes.  :notnew:
	def initialize( * )
		@subnodes = []
		super
		yield( self ) if block_given?
	end


	# The nodes the tag contains
	attr_reader :subnodes


	### Append operator: add nodes to the correct part of the parse tree.
	def <<( node )
		@subnodes << node
		return self
	end


	### Tell the parser to expect a matching <?end ?> tag.
	def is_container?
		return true
	end
	alias_method :container?, :is_container?


	### Default render method for containertags; rendering each of its subnodes and
	### don't render anything for the container itself.
	def render( renderstate )
		self.render_subnodes( renderstate )
	end


	### Append the container's subnodes to the +renderstate+.
	def render_subnodes( renderstate )
		self.subnodes.each {|node| renderstate << node }
	end

end # module Inversion::Template::ContainerTag


