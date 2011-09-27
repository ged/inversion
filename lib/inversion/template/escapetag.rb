#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/attrtag'

# Inversion escaping tag.
#
# This tag is a derivative of the 'attr' tag that escapes the results of its method call
# via the format specified in the template config option 'escape_format'.
#
# == Syntax
#
#   <?escape foo.bar ?>
#   <?escape "Got <%d> items at <$%0.2f>" % [ line_item.count, line_item.price ] ?>
#
class Inversion::Template::EscapeTag < Inversion::Template::AttrTag
	include Inversion::Escaping

	### Render the method chains against the attributes of the specified +render_state+
	### and return them.
	def render( render_state )
		return self.escape( super, render_state )
	end

end # class Inversion::Template::EscapeTag

