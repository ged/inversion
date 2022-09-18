# -*- ruby -*-
# vim: set noet nosta sw=4 ts=4 :

require 'uri'
require 'inversion/template' unless defined?( Inversion::Template )
require 'inversion/template/attrtag'

# Inversion URL encoding tag.
#
# This tag is a derivative of the 'attr' tag that encodes the results of its method call
# according to RFC 3986.
#
# == Syntax
#
#   <?uriencode foo.bar ?>
#
class Inversion::Template::UriencodeTag < Inversion::Template::AttrTag
	include Inversion::Escaping


	### Render the method chains against the attributes of the specified +render_state+
	### and return them.
	def render( render_state )
		raw = super
		return escape_uri( raw.to_s )
	end

end # class Inversion::Template::UriencodeTag

