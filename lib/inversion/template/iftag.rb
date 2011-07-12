#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/mixins'
require 'inversion/template/attrtag'
require 'inversion/template/containertag'
require 'inversion/template/conditionaltag'
require 'inversion/template/elsiftag'
require 'inversion/template/elsetag'

# Inversion 'if' tag.
#
# This tag causes a section of the template to be rendered only if its methodchain or attribute
# is a true value.
#
# == Syntax
#
#   <?if attr ?>...<?end?>
#   <?if obj.method ?>...<?end?>
#
class Inversion::Template::IfTag < Inversion::Template::AttrTag
	include Inversion::Loggable,
	        Inversion::Template::ContainerTag,
	        Inversion::Template::ConditionalTag

	# Inherits AttrTag's tag patterns

	### Render the tag's contents if the condition is true, or any else or elsif sections
	### if the condition isn't true.
	def render( state )
		self.enable_rendering if super
		self.render_subnodes( state )
	end


	### Render the tag's subnodes according to the tag's logical state.
	def render_subnodes( renderstate )
		self.log.debug "Rendering subnodes. Rendering initially %s" %
			[ self.rendering_enabled? ? "enabled" : "disabled" ]

		# walk the subtree, modifying the logic flags for else and elsif tags,
		# and rendering nodes if rendering is enabled
		self.subnodes.each do |node|
			case node
			when Inversion::Template::ElsifTag
				self.log.debug "  logic switch: %p..." % [ node ]
				if !self.rendering_was_enabled? && node.render( renderstate )
					self.enable_rendering
				else
					self.disable_rendering
				end

			when Inversion::Template::ElseTag
				self.log.debug "  logic switch: %p..." % [ node ]
				if !self.rendering_was_enabled?
					self.enable_rendering
				else
					self.disable_rendering
				end

			else
				renderstate << node if self.rendering_enabled?
			end
		end
	end

end # class Inversion::Template::IfTag

