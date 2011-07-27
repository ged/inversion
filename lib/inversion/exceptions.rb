#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

#--
module Inversion

	# An exception class raised from the Inversion::Template::Parser when
	# a problem is encountered while parsing a template.
	class ParseError < ::RuntimeError; end

	# An exception class raised when a problem is detected in a template
	# configuration option.
	class OptionsError < ::RuntimeError; end

	# An exception class raised when a template includes itself, either
	# directly or indirectly.
	class StackError < ::RuntimeError; end

end # module Inversion


