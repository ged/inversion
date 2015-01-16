# -*- ruby -*-
#encoding: utf-8
# vim: set noet nosta sw=4 ts=4 :

require 'loggability'

# The Inversion templating system. This module provides the namespace for all the other
# classes and modules, and contains the logging subsystem. A good place to start for
# documentation would be to check out the examples in the README, and then
# Inversion::Template for a list of tags, configuration options, etc.
#
# == Authors
#
# * Michael Granger <ged@FaerieMUD.org>
# * Mahlon E. Smith <mahlon@martini.nu>
#
# :main: README.rdoc
#
module Inversion
	extend Loggability

	# Loggability API -- set up a log host for the Inversion library
	log_as :inversion


	warn ">>> Inversion requires Ruby 2.0.0 or later. <<<" if RUBY_VERSION < '2.0.0'

	# Library version constant
	VERSION = '0.17.1'

	# Version-control revision constant
	REVISION = %q$Revision$


	### Get the Inversion version.
	def self::version_string( include_buildnum=false )
		vstring = "%s %s" % [ self.name, VERSION ]
		vstring << " (build %s)" % [ REVISION[/: ([[:xdigit:]]+)/, 1] || '0' ] if include_buildnum
		return vstring
	end

	require 'inversion/exceptions'
	require 'inversion/mixins'
	require 'inversion/monkeypatches'
	require 'inversion/template'

end # module Inversion

