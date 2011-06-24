#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

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
	include Inversion::Loggable,
			Inversion::Template::ContainerTag

	# Inherits AttrTag's tag patterns


	######
	public
	######

	### Render the content's subnodes if the condition is true.
	### @param [Inversion::RenderState] state  the current rendering state
	def render( state )
		value = super
		self.log.debug "Conditional value: %p" % [ value ]
		return nil unless value

		result = []

		self.subnodes.each do |node|
			result << node.render( state )
		end

		return result.join
	end


	### Render the tag as the body of a comment, suitable for template 
	### debugging.
	### @return [String]  the tag as the body of a comment
	# def as_comment_body
	# end

end # class Inversion::Template::IfTag

