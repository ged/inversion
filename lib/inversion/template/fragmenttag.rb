#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/tag'
require 'inversion/template/containertag'


# Inversion 'fragment' tag.
#
# This tag provides a way to generate a fragment of content once in a template
# as an attribute, and then reuse it later either in the same template or even
# outside of it.
#
# == Syntax
#
#   <?fragment subject ?>Receipt for Order #<?call order.number ?><?end subject ?>
#
class Inversion::Template::FragmentTag < Inversion::Template::Tag
	include Inversion::Template::ContainerTag


	### Create a new FragmentTag with the given +body+.
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

	# The fragment key; corresponds to the name of the attribute that will be set
	# by the rendered contents of the fragment.
	attr_reader :key


	### Render the fragment and store it as an attribute.
	def render( renderstate )
		self.log.debug "Publishing %d nodes as %s" % [ self.subnodes.length, self.key ]
		rendered_nodes = []
		renderstate.with_destination( rendered_nodes ) do
			sn = self.render_subnodes( renderstate )
			# self.log.debug "  subnodes are: %p" % [ sn ]
			sn
		end

		# self.log.debug "  rendered nodes are: %p" % [ rendered_nodes ]
		renderstate.add_fragment( self.key, rendered_nodes )

		return nil
	end


end # class Inversion::Template::FragmentTag

