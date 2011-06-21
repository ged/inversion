#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/calltag'

# Inversion escaping tag.
#
# This tag is a derivative of the 'call' tag that escapes the results of its method call
# via the format specified in the template config option 'escape_format'.
#
# == Syntax
#
#   <?escape foo.bar ?>
#   <?escape "Got <%d> items at <$%0.2f>" % [ line_item.count, line_item.price ] ?>
#
class Inversion::Template::EscapeTag < Inversion::Template::CallTag

	# The fallback escape format
	DEFAULT_ESCAPE_FORMAT = :html


	### Render the method chains against the attributes of the specified +render_state+
	### and return them.
	def render( render_state=nil )
		return '' if render_state.nil?
		format = render_state.options[:escape_format] || DEFAULT_ESCAPE_FORMAT
		result = self.escape( super, format )
	end


	#########
	protected
	#########

	### Escape the +output+ using the specified +format+.
	def escape( output, format )
		unless self.respond_to?( "escape_#{format}" )
			self.log.error "Format %p not supported. To add support, define a #escape_%s to %s" %
				[ format, format, __FILE__ ]
			raise Inversion::OptionsError, "No such escape format %p" % [ format ]
		end

		return self.__send__( "escape_#{format}", output )
	end


	### Escape the given +output+ using HTML entity-encoding.
	def escape_html( output )
		return output.
			gsub( /&/, '&amp;' ).
			gsub( /</, '&lt;' ).
			gsub( />/, '&gt;' )
	end

end # class Inversion::Template::EscapeTag

