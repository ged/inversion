# -*- ruby -*-
# vim: set noet nosta sw=4 ts=4 :

require 'loggability'
require 'gli'
require 'tty/prompt'
require 'tty/table'
require 'pastel'

require 'inversion' unless defined?( Inversion )
require 'inversion/mixins'


# Command class for the 'inversion' command-line tool.
class Inversion::CLI
	extend Loggability,
		Inversion::MethodUtilities,
		GLI::App


	# Write logs to Assemblage's logger
	log_to :inversion


	#
	# GLI
	#

	# Set up global[:description] and options
	program_desc 'Inversion'

	# The command version
	version Inversion::VERSION

	# Use an OpenStruct for options instead of a Hash
	use_openstruct( true )

	# Subcommand options are independent of global[:ones]
	subcommand_option_handling :normal

	# Strict argument validation
	arguments :strict


	# Custom parameter types
	accept Array do |value|
		value.strip.split(/\s*,\s*/)
	end
	accept Pathname do |value|
		Pathname( value.strip )
	end


	# Global options
	desc 'Enable debugging output'
	switch [:d, :debug]

	desc 'Enable verbose output'
	switch [:v, :verbose]

	desc 'Set log level to LEVEL (one of %s)' % [Loggability::LOG_LEVELS.keys.join(', ')]
	arg_name :LEVEL
	flag [:l, :loglevel], must_match: Loggability::LOG_LEVELS.keys

	desc 'Ignore unknown tags instead of displaying an error'
	switch 'ignore-unknown-tags'

	desc 'Add one or more PATHS to the template search path'
	arg_name :PATH
	flag [:p, :path], type: Pathname, multiple: true


	#
	# GLI Event callbacks
	#

	# Set up global options
	pre do |global, command, options, args|
		self.set_logging_level( global[:l] )
		Loggability.format_with( :color ) if $stdout.tty?


		# Include a 'lib' directory if there is one
		$LOAD_PATH.unshift( 'lib' ) if File.directory?( 'lib' )

		self.setup_pastel_aliases
		self.setup_output( global )

		# Configure Inversion's strictness
		Inversion::Template.configure(
			:ignore_unknown_tags => global.ignore_unknown_tags,
			:template_paths      => global.path,
		)

		true
	end


	# Write the error to the log on exceptions.
	on_error do |exception|

		case exception
		when OptionParser::ParseError, GLI::CustomExit
			msg = exception.full_message(highlight: false, order: :bottom)
			self.log.debug( msg )
		else
			msg = exception.full_message(highlight: true, order: :bottom)
			self.log.error( msg )
		end

		true
	end




	##
	# Registered subcommand modules
	singleton_attr_accessor :subcommand_modules


	### Overridden -- Add registered subcommands immediately before running.
	def self::run( * )
		self.add_registered_subcommands
		super
	end


	### Add the specified `mod`ule containing subcommands to the 'inversion' command.
	def self::register_subcommands( mod )
		self.subcommand_modules ||= []
		self.subcommand_modules.push( mod )
		mod.extend( GLI::DSL, GLI::AppSupport, Loggability )
		mod.log_to( :inversion )
	end


	### Add the commands from the registered subcommand modules.
	def self::add_registered_subcommands
		self.subcommand_modules ||= []
		self.subcommand_modules.each do |mod|
			merged_commands = mod.commands.merge( self.commands )
			self.commands.update( merged_commands )
			command_objs = self.commands_declaration_order | self.commands.values
			self.commands_declaration_order.replace( command_objs )
		end
	end


	### Return the Pastel colorizer.
	###
	def self::pastel
		@pastel ||= Pastel.new( enabled: $stdout.tty? )
	end


	### Return the TTY prompt used by the command to communicate with the
	### user.
	def self::prompt
		@prompt ||= TTY::Prompt.new( output: $stderr )
	end


	### Discard the existing HighLine prompt object if one existed. Mostly useful for
	### testing.
	def self::reset_prompt
		@prompt = nil
	end


	### Set the global logging `level` if it's defined.
	def self::set_logging_level( level=nil )
		if level
			Loggability.level = level.to_sym
		else
			Loggability.level = :fatal
		end
	end


	### Load any additional Ruby libraries given with the -r global option.
	def self::require_additional_libs( requires)
		requires.each do |path|
			path = "inversion/#{path}" unless path.start_with?( 'inversion/' )
			require( path )
		end
	end


	### Setup pastel color aliases
	###
	def self::setup_pastel_aliases
		self.pastel.alias_color( :headline, :bold, :white, :on_black )
		self.pastel.alias_color( :success, :bold, :green )
		self.pastel.alias_color( :error, :bold, :red )
		self.pastel.alias_color( :up, :green )
		self.pastel.alias_color( :down, :red )
		self.pastel.alias_color( :unknown, :dark, :yellow )
		self.pastel.alias_color( :disabled, :dark, :white )
		self.pastel.alias_color( :quieted, :dark, :green )
		self.pastel.alias_color( :acked, :yellow )
		self.pastel.alias_color( :highlight, :bold, :yellow )
		self.pastel.alias_color( :search_hit, :black, :on_white )
		self.pastel.alias_color( :prompt, :cyan )
		self.pastel.alias_color( :even_row, :bold )
		self.pastel.alias_color( :odd_row, :reset )
	end


	### Set up the output levels and globals based on the associated `global` options.
	def self::setup_output( global )

		if global[:verbose]
			$VERBOSE = true
			Loggability.level = :info
		end

		if global[:debug]
			$DEBUG = true
			Loggability.level = :debug
		end

		if global[:loglevel]
			Loggability.level = global[:loglevel]
		end

	end


	#
	# GLI subcommands
	#


	# Convenience module for subcommand registration syntax sugar.
	module Subcommand

		### Extension callback -- register the extending object as a subcommand.
		def self::extended( mod )
			Inversion::CLI.log.debug "Registering subcommands from %p" % [ mod ]
			Inversion::CLI.register_subcommands( mod )
		end


		###############
		module_function
		###############

		### Exit with the specified `exit_code` after printing the given `message`.
		def exit_now!( message, exit_code=1 )
			raise GLI::CustomExit.new( message, exit_code )
		end


		### Exit with a helpful `message` and display the usage.
		def help_now!( message=nil )
			exception = OptionParser::ParseError.new( message )
			def exception.exit_code; 64; end

			raise exception
		end


		### Get the prompt (a TTY::Prompt object)
		def prompt
			return Inversion::CLI.prompt
		end


		### Return the global Pastel object for convenient formatting, color, etc.
		def hl
			return Inversion::CLI.pastel
		end


		### Return the specified `string` in the 'headline' ANSI color.
		def headline_string( string )
			return hl.headline( string )
		end


		### Return the specified `string` in the 'highlight' ANSI color.
		def highlight_string( string )
			return hl.highlight( string )
		end


		### Return the specified `string` in the 'success' ANSI color.
		def success_string( string )
			return hl.success( string )
		end


		### Return the specified `string` in the 'error' ANSI color.
		def error_string( string )
			return hl.error( string )
		end


		### Output a table with the given `header` (an array) and `rows`
		### (an array of arrays).
		def display_table( header, rows )
			table = TTY::Table.new( header, rows )
			renderer = nil

			if hl.enabled?
				renderer = TTY::Table::Renderer::Unicode.new(
					table,
					multiline: true,
					padding: [0,1,0,1]
				)
				renderer.border.style = :dim

			else
				renderer = TTY::Table::Renderer::ASCII.new(
					table,
					multiline: true,
					padding: [0,1,0,1]
				)
			end

			puts renderer.render
		end


		### Display the given list of `items`.
		def display_list( items )
			items.flatten.each do |item|
				self.prompt.say( "- %s" % [ self.highlight_string(item) ] )
			end

		end


		### Return the count of visible (i.e., non-control) characters in the given `string`.
		def visible_chars( string )
			return string.to_s.gsub(/\e\[.*?m/, '').scan( /\P{Cntrl}/ ).size
		end


		### In dry-run mode, output the description instead of running the provided block and
		### return the `return_value`.
		### If dry-run mode is not enabled, yield to the block.
		def unless_dryrun( description, return_value=true )
			if $DRYRUN
				self.log.warn( "DRYRUN> #{description}" )
				return return_value
			else
				return yield
			end
		end
		alias_method :unless_dry_run, :unless_dryrun



		### Load the Inversion::Template from the specified `tmplpath` and return it. If there
		### is an error loading the template, output the error and return `nil`.
		def load_template( tmplpath )
			template = Inversion::Template.load( tmplpath )
			return template
		rescue Errno => err
			self.prompt.say "Failed to load %s: %s" % [ tmplpath, err.message ]
			return nil
		rescue Inversion::ParseError => err
			self.prompt.say "%s: Invalid template: %p: %s" %
				[ tmplpath, err.class, err.message ]
			self.prompt.say( err.backtrace.join("\n  ") ) if $DEBUG
			return nil
		end


		### Output a blank line
		def output_blank_line
			self.prompt.say( "\n" )
		end


		### Output a header between each template.
		def output_template_header( template )
			header_info = "%s (%0.2fK, %s)" %
				[ template.source_file, template.source.bytesize/1024.0, template.source.encoding ]
			header_line = "-- %s" % [ header_info ]
			self.prompt.say( headline_string header_line )
		end


		### Output a subheader with the given `caption`.
		def output_subheader( caption )
			self.prompt.say( highlight_string caption )
		end

	end # module Subcommand


	### Load commands from any files in the specified directory relative to LOAD_PATHs
	def self::commands_from( subdir )
		Gem.find_latest_files( File.join(subdir, '*.rb') ).each do |rbfile|
			self.log.debug "  loading %s..." % [ rbfile ]
			require( rbfile )
		end
	end


	commands_from 'inversion/cli'

end # class Inversion::CLI
