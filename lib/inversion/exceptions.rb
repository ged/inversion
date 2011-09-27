#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

#--
module Inversion

	# A generic Inversion exception class
	class Error < ::RuntimeError; end

	# An exception class raised from the Inversion::Parser when
	# a problem is encountered while parsing a template.
	class ParseError < Inversion::Error; end

	# An exception class raised when a problem is detected in a template
	# configuration option.
	class OptionsError < Inversion::Error; end

	# An exception class raised when a template includes itself, either
	# directly or indirectly.
	class StackError < Inversion::Error; end

end # module Inversion


