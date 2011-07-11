#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'pp'
require 'inversion/template/calltag'

# Inversion object inspection tag.
#
# This tag dumps the result of the attribute or method chain.
#
# == Syntax
#
#   <?pp foo.bar ?>
#
class Inversion::Template::PpTag < Inversion::Template::CallTag
	include Inversion::Escaping

	### Render the method chains against the attributes of the specified +render_state+
	### and return them.
	def render( render_state )
		raw = super
		buf = ''
		PP.pp( raw, buf )
		return self.escape( buf.chomp, render_state )
	end

end # class Inversion::Template::PpTag

