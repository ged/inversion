#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'logger'


# The Inversion templating system. This module provides the namespace for all the other
# classes and modules, and contains the logging subsystem. A good place to start for 
# documentation would be to check out the examples in the README, and then 
# {Inversion::Template} for a list of tags, configuration options, etc.
#
# @author Michael Granger <ged@FaerieMUD.org>
# @author Mahlon E. Smith <mahlon@martini.nu>
#
module Inversion

	require 'inversion/exceptions'
	require 'inversion/mixins'
	require 'inversion/utils'
	require 'inversion/monkeypatches'

	# Library version constant
	VERSION = '0.0.1'

	# Version-control revision constant
	REVISION = %q$Revision$

	### Logging
	# Log levels
	LOG_LEVELS = {
		'debug' => Logger::DEBUG,
		'info'  => Logger::INFO,
		'warn'  => Logger::WARN,
		'error' => Logger::ERROR,
		'fatal' => Logger::FATAL,
	}.freeze
	LOG_LEVEL_NAMES = LOG_LEVELS.invert.freeze

	@default_logger = Logger.new( $stderr )
	@default_logger.level = $DEBUG ? Logger::DEBUG : Logger::WARN

	@default_log_formatter = Inversion::LogFormatter.new( @default_logger )
	@default_logger.formatter = @default_log_formatter

	@logger = @default_logger


	class << self
		# @return [Logger::Formatter] the log formatter that will be used when the logging 
		#    subsystem is reset
		attr_accessor :default_log_formatter

		# @return [Logger] the logger that will be used when the logging subsystem is reset
		attr_accessor :default_logger

		# @return [Logger] the logger that's currently in effect
		attr_accessor :logger
		alias_method :log, :logger
		alias_method :log=, :logger=
	end


	### Reset the global logger object to the default
	### @return [void]
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
	### @return [String] the library's version
	def self::version_string( include_buildnum=false )
		vstring = "%s %s" % [ self.name, VERSION ]
		vstring << " (build %s)" % [ REVISION[/: ([[:xdigit:]]+)/, 1] || '0' ] if include_buildnum
		return vstring
	end

	require 'inversion/template'

end # module Inversion

