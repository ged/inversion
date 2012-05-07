#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/mixins'
require 'inversion/template/attrtag'
require 'inversion/template/containertag'

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
	include Inversion::Template::ContainerTag

	# Inherits AttrTag's tag patterns

	### Render the tag's contents if the condition is true, or any else or elsif sections
	### if the condition isn't true.
	def render( state )

		# Start out with rendering enabled if the tag body evaluates trueishly
		if self.evaluate( state )
			self.log.debug "Initial state was TRUE; enabling rendering"
			state.enable_rendering
		else
			self.log.debug "Initial state was FALSE; disabling rendering"
			state.disable_rendering
		end

		# Set the tag state to track whether or not rendering has been enabled during the
		# 'if' for an 'else' or 'elsif' tag.
		state.with_tag_data( rendering_was_enabled: state.rendering_enabled? ) do
			super
		end

		state.enable_rendering
		return nil
	end


end # class Inversion::Template::IfTag

