#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'pathname'
require 'inversion/mixins'
require 'inversion/template/tag'


# Inversion 'yield' tag.
#
# A tag that yields to the block passed to Template#render (if there was one), and
# then inserts the resulting objects.
#
# == Example
#
#   <?yield ?>
#
class Inversion::Template::YieldTag < Inversion::Template::Tag

	######
	public
	######

	### Rendering callback -- call the block before the template this tag
	### belongs to is rendered.
	def before_rendering( renderstate )
		if renderstate.block
			self.log.debug "Yielding to %p before rendering." % [ renderstate.block ]
			renderstate.tag_data[ self ] = renderstate.block.call( renderstate )
			self.log.debug "  render block returned: %p" % [ @block_value ]
		end
	end


	### Render the YieldTag by returning what the #render block returned during
	### #before_rendering (if there was a block).
	def render( renderstate )
		self.log.debug "Rendering as block return value: %p" % [ @block_value ]
		return renderstate.tag_data[ self ]
	end


end # class Inversion::Template::YieldTag

