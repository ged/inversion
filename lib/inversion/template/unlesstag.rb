#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/mixins'
require 'inversion/template/attrtag'
require 'inversion/template/containertag'
require 'inversion/template/conditionaltag'


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
	include Inversion::Loggable,
	        Inversion::Template::ContainerTag,
	        Inversion::Template::ConditionalTag

	# Inherits AttrTag's tag patterns

	### Render the tag's contents if the condition is true, or any else or elsif sections
	### if the condition isn't true.
	def render( state )
		self.enable_rendering unless super
		return self.render_subnodes( state )
	end

end # class Inversion::Template::UnlessTag

