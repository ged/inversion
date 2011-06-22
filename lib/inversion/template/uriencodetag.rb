#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'uri'
require 'inversion/template/calltag'

# Inversion URL encoding tag.
#
# This tag is a derivative of the 'call' tag that encodes the results of its method call
# according to RFC 3986.
#
# == Syntax
#
#   <?uriencode foo.bar ?>
#
class Inversion::Template::UriencodeTag < Inversion::Template::CallTag

	# Unreserved characters from section 2.3 of RFC 3986
 	# ALPHA / DIGIT / "-" / "." / "_" / "~"
	DEFAULT_ENCODED_CHARACTERS = /[^\w\-\.~]/

	### Render the method chains against the attributes of the specified +render_state+
	### and return them.
	def render( render_state=nil )
		raw = super
		return URI.encode( raw, DEFAULT_ENCODED_CHARACTERS )
	end

end # class Inversion::Template::UriencodeTag

