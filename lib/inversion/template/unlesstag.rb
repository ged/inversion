#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/mixins'
require 'inversion/template/attrtag'
require 'inversion/template/containertag'
require 'inversion/template/elsetag'


# Inversion 'unless' tag.
#
# This tag causes a section of the template to be rendered only if its methodchain or attribute
# is a *false* value.
#
# == Syntax
#
#   <?unless attr ?>...<?end?>
#   <?unless obj.method ?>...<?end?>
#
class Inversion::Template::UnlessTag < Inversion::Template::AttrTag
	include Inversion::Template::ContainerTag

	# Inherits AttrTag's tag patterns

	### Render the tag's contents if the condition is true, or any else or elsif sections
	### if the condition isn't true.
	def render( state )

		# Start out with rendering *disabled* if the tag body evaluates trueishly
		if self.evaluate( state )
			self.log.debug "Initial state was TRUE; disabling rendering"
			state.disable_rendering
		else
			self.log.debug "Initial state was FALSE; enabling rendering"
			state.enable_rendering
		end

		# Set the tag state to track whether or not rendering has been enabled during the
		# 'unless' for an 'else' tag.
		state.with_tag_data( :rendering_was_enabled => state.rendering_enabled? ) do
			self.render_subnodes( state )
		end

		state.enable_rendering
		return nil
	end

end # class Inversion::Template::UnlessTag

