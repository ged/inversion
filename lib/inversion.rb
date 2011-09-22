#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'logger'


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

	warn ">>> Inversion requires Ruby 1.9.2 or later. <<<" if RUBY_VERSION < '1.9.2'

	require 'inversion/exceptions'
	require 'inversion/mixins'
	require 'inversion/utils'
	require 'inversion/monkeypatches'

	# Library version constant
	VERSION = '0.0.4'

	# Version-control revision constant
	REVISION = %q$Revision$

	#
	# Logging
	#

	# Log levels
	LOG_LEVELS = {
		'debug' => Logger::DEBUG,
		'info'  => Logger::INFO,
		'warn'  => Logger::WARN,
		'error' => Logger::ERROR,
		'fatal' => Logger::FATAL,
	}.freeze

	# Log levels keyed by level
	LOG_LEVEL_NAMES = LOG_LEVELS.invert.freeze

	@default_logger = Logger.new( $stderr )
	@default_logger.level = $DEBUG ? Logger::DEBUG : Logger::WARN

	@default_log_formatter = Inversion::LogFormatter.new( @default_logger )
	@default_logger.formatter = @default_log_formatter

	@logger = @default_logger


	class << self
		# the log formatter that will be used when the logging subsystem is reset
		attr_accessor :default_log_formatter

		# the logger that will be used when the logging subsystem is reset
		attr_accessor :default_logger

		# the logger that's currently in effect
		attr_accessor :logger
		alias_method :log, :logger
		alias_method :log=, :logger=
	end


	### Reset the global logger object to the default
	def self::reset_logger
		self.logger = self.default_logger
		self.logger.level = Logger::WARN
		self.logger.formatter = self.default_log_formatter
	end


	### Returns +true+ if the global logger has not been set to something other than
	### the default one.
	def self::using_default_logger?
		return self.logger == self.default_logger
	end


	### Get the Inversion version.
	def self::version_string( include_buildnum=false )
		vstring = "%s %s" % [ self.name, VERSION ]
		vstring << " (build %s)" % [ REVISION[/: ([[:xdigit:]]+)/, 1] || '0' ] if include_buildnum
		return vstring
	end

	require 'inversion/template'

end # module Inversion

