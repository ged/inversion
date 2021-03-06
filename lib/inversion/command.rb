# -*- ruby -*-
# frozen_string_literal: true
# vim: set noet nosta sw=4 ts=4 :

require 'logger'
require 'trollop'
require 'highline'
require 'sysexits'
require 'shellwords'

require 'inversion' unless defined?( Inversion )


# Command class for the 'inversion' command-line tool.
class Inversion::Command
	extend Sysexits

	# The list of valid subcommands
	SUBCOMMANDS = %w[api tagtokens tree]

	# Class-instance variable for the HighLine prompt object
	@prompt = nil


	### Run the command
	def self::run( args )
		opts, args = self.parse_options( args )
		subcommand = args.shift

		command = self.new( opts )
		command.run( subcommand, args )
	rescue => err
		$stderr.puts "%p: %s" % [ err.class, err.message ]
		$stderr.puts( err.backtrace.join("\n  ") ) if opts && opts.debug
	end


	### Fetch the HighLine instance for the command, creating it if necessary.
	def self::prompt
		unless @prompt
			@prompt = HighLine.new
			@prompt.page_at = @prompt.output_rows - 5
			@prompt.wrap_at = @prompt.output_cols - 2
		end

		@prompt
	end


	### Create an option parser for the command and return it
	def self::create_option_parser
		pr = self.prompt
		progname = pr.color( File.basename($0), :bold, :yellow )

		return Trollop::Parser.new do
			version Inversion.version_string( true )

			banner (<<-END_BANNER).gsub(/^\t+/, '')
			#{progname} OPTIONS SUBCOMMAND ARGS

			Run the specified SUBCOMMAND with the given ARGS.
			END_BANNER
			text ''

			stop_on( *SUBCOMMANDS )
			text pr.color('Subcommands', :bold, :white)
			text pr.list( SUBCOMMANDS, :columns_across )
			text ''

			text pr.color('Inversion Config', :bold, :white)
			opt :ignore_unknown_tags, "Ignore unknown tags instead of displaying an error"
			opt :path, "Add one or more directories to the template search path",
				:type => :string, :multi => true
			text ''


			text pr.color('Other Options', :bold, :white)
			opt :debug, "Enable debugging output"
		end
	end


	### Parse the given command line +args+, returning a populated options struct
	### and any remaining arguments.
	def self::parse_options( args )
		oparser = self.create_option_parser
		opts = oparser.parse( args )

		if oparser.leftovers.empty?
			$stderr.puts "No subcommand given.\nUsage: "
			oparser.educate( $stderr )
			exit :usage
		end
		args.replace( oparser.leftovers )

		return opts, args
	rescue Trollop::HelpNeeded
		oparser.educate( $stderr )
		exit :ok
	rescue Trollop::VersionNeeded
		$stderr.puts( oparser.version )
		exit :ok
	end


	### Create a new instance of the command that will use the specified +opts+
	### to parse and dump info about the given +templates+.
	def initialize( opts )
		@opts      = opts
		@prompt    = self.class.prompt

		# Configure logging
		Loggability.level = opts.debug ? :debug : :error
		Loggability.format_with( :color ) if $stdin.tty?

		# Configure Inversion's strictness
		Inversion::Template.configure(
			:ignore_unknown_tags => opts.ignore_unknown_tags,
			:template_paths      => opts.path,
		)
	end


	######
	public
	######

	# The command-line options
	attr_reader :opts

	# The command's prompt object (HighLine)
	attr_reader :prompt


	### Run the given +subcommand+ with the specified +args+.
	def run( subcommand, args )
		case subcommand.to_sym
		when :tree
			self.dump_node_trees( args )
		when :api
			self.describe_templates( args )
		when :tagtokens
			self.dump_tokens( args )
		else
			self.output_error( "No such command #{subcommand.dump}" )
		end
	end


	### Load the Inversion::Template from the specified +tmplpath+ and return it. If there
	### is an error loading the template, output the error and return +nil+.
	def load_template( tmplpath )
		template = Inversion::Template.load( tmplpath )
		return template
	rescue Errno => err
		self.prompt.say "Failed to load %s: %s" % [ tmplpath, err.message ]
	rescue Inversion::ParseError => err
		self.prompt.say "%s: Invalid template: %p: %s" %
			[ tmplpath, err.class, err.message ]
		self.prompt.say( err.backtrace.join("\n  ") ) if self.opts.debug
	end


	### Dump the node tree of the given +templates+.
	def dump_node_trees( templates )
		templates.each do |path|
			template = self.load_template( path )
			self.output_blank_line
			self.output_template_header( template )
			self.output_template_nodes( template.node_tree )
		end
	end


	### Output the given +tree+ of nodes at the specified +indent+ level.
	def output_template_nodes( tree, indent=0 )
		indenttxt = ' ' * indent
		tree.each do |node|
			self.prompt.say( indenttxt + node.as_comment_body )
			self.output_template_nodes( node.subnodes, indent+4 ) if node.is_container?
		end
	end


	### Output a description of the templates.
	def describe_templates( templates )
		templates.each do |path|
			template = self.load_template( path )
			self.output_blank_line
			self.output_template_header( template )
			self.describe_template_api( template )
			self.describe_publications( template )
			self.describe_subscriptions( template )
		end
	end


	### Output a header between each template.
	def output_template_header( template )
		header_info = "%s (%0.2fK, %s)" %
			[ template.source_file, template.source.bytesize/1024.0, template.source.encoding ]
		header_line = "-- %s" % [ header_info ]
		self.prompt.say( self.prompt.color(header_line, :bold, :white) )
	end


	### Output a description of the +template+'s attributes, subscriptions, etc.
	def describe_template_api( template )
		attrs = template.attributes.keys.map( &:to_s )
		return if attrs.empty?

		self.output_subheader "%d Attribute/s" % [ attrs.length ]
		self.output_list( attrs.sort )
		self.output_blank_line
	end


	### Output a list of sections the template publishes.
	def describe_publications( template )
		ptags = template.node_tree.find_all {|node| node.is_a?(Inversion::Template::PublishTag) }
		return if ptags.empty?

		pubnames = ptags.map( &:key ).map( &:to_s ).uniq.sort
		self.output_subheader "%d Publication/s" % [ pubnames.length ]
		self.output_list( pubnames )
		self.output_blank_line
	end


	### Output a list of sections the template subscribes to.
	def describe_subscriptions( template )
		stags = template.node_tree.find_all {|node| node.is_a?(Inversion::Template::SubscribeTag) }
		return if stags.empty?

		subnames = stags.map( &:key ).map( &:to_s ).uniq.sort
		self.output_subheader "%d Subscription/s" % [ subnames.length ]
		self.output_list( subnames )
		self.output_blank_line
	end


	### Attempt to parse the given +code+ and dump its tokens as a tagpattern.
	def dump_tokens( args )
		code = args.join(' ')

		require 'ripper'
		tokens = Ripper.lex( code ).collect do |(pos, tok, text)|
			"%s<%p>" % [ tok.to_s.sub(/^on_/,''), text ]
		end.join(' ')

		self.prompt.say( tokens )
	end


	### Display a columnar list.
	def output_list( columns )
		self.prompt.say( self.prompt.list(columns, :columns_down) )
	end


	### Display an error message.
	def output_error( message )
		self.prompt.say( self.prompt.color(message, :red) )
	end


	### Output a subheader with the given +caption+.
	def output_subheader( caption )
		self.prompt.say( self.prompt.color(caption, :cyan) )
	end


	### Output a blank line
	def output_blank_line
		self.prompt.say( "\n" )
	end

end # class Inversion::Command
