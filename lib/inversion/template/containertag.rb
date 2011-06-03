#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion' unless defined?( Inversion )
require 'inversion/template' unless defined?( Inversion::Template )

# A mixin for a tag that allows it to contain other nodes.
#
# @author Michael Granger <ged@FaerieMUD.org>
# @author Mahlon E. Smith <mahlon@martini.nu>
#
module Inversion::Template::ContainerTag

	### Setup subnodes for including classes.  :notnew:
	def initialize( * )
		@subnodes = []
		super
	end

	# @return [Array<Inversion::Template::Node>] the nodes the tag contains
	attr_reader :subnodes


	### Append operator: add nodes to the correct part of the parse tree.
	### @param [Inversion::Template::Node] node  the parsed node
	def <<( node )
		@subnodes << node
		return self
	end


	### Tell the parser to expect a matching <?end ?> tag.
	def is_container?
		return true
	end
	alias_method :container?, :is_container?

end # module Inversion::Template::ContainerTag


