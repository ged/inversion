# -*- ruby -*-
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/mixins'
require 'inversion/template' unless defined?( Inversion::Template )
require 'inversion/template/attrtag'
require 'inversion/template/containertag'

using Inversion::Refinements


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

	# Inherit AttrTag's tag patterns first.
	inherit_tag_patterns

	# Append a 'not' tag matcher.
	# <?if ! foo ?>, <?if !foo ?>
	#
	tag_pattern '$(op) sp* $(ident)' do |tag, match|
		op = match.string( 1 )
		raise Inversion::ParseError, "expected '!', got %p instead" % [ op ] unless op == '!'

		tag.send( :log ).debug "  Identifier is: %p (inverted)" % [ match.string(2) ]
		tag.name = match.string( 2 ).to_sym
		tag.inverted = true
	end


	### Create a new IfTag.
	def initialize( body, linenum=nil, colnum=nil )
		@inverted = false
		super
	end

	# Invert the tag's renderstate if created with the 'not' operator.
	attr_accessor :inverted


	### Render the tag's contents if the condition is true, or any else or elsif sections
	### if the condition isn't true.
	def render( renderstate )

		evaluated_state = self.evaluate( renderstate )
		evaluated_state = ! evaluated_state if self.inverted

		# Start out with rendering enabled if the tag body evaluates trueishly
		if evaluated_state
			self.log.debug "Initial state was TRUE; enabling rendering"
			renderstate.enable_rendering
		else
			self.log.debug "Initial state was FALSE; disabling rendering"
			renderstate.disable_rendering
		end

		# Set the tag state to track whether or not rendering has been enabled during the
		# 'if' for an 'else' or 'elsif' tag.
		renderstate.with_tag_data( rendering_was_enabled: renderstate.rendering_enabled? ) do
			super
		end

		renderstate.enable_rendering
		return nil
	end


end # class Inversion::Template::IfTag

