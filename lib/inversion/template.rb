#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'loggability'
require 'pathname'
require 'inversion' unless defined?( Inversion )

# Load the Configurability library if it's installed
begin
	require 'configurability'
	require 'configurability/config'
rescue LoadError
end


# The main template class.
#
# Inversion templates are the primary objects you'll be interacting with. Templates
# can be created from a string:
#
#   Inversion::Template.new( template_source )
#
# or from a file:
#
#   Inversion::Template.load( 'path/to/template.tmpl' )
#
#
# == Template Options
#
# Inversion supports the {Configurability}[http://rubygems.org/gems/configurability]
# API, and registers itself with the +templates+ key. This means you can either add
# a +templates+ section to your Configurability config, or call
# ::configure yourself with a config Hash (or something that quacks like one).
#
# To set options on a per-template basis, you can pass an options hash to either
# Inversion::Template::load or Inversion::Template::new, or set them from within the template
# itself using the {config tag}[rdoc-ref:Tags@config].
#
# The available options are:
#
# [:ignore_unknown_tags]
#   Setting to false causes unknown tags used in templates to raise an
#   Inversion::ParseError. Defaults to +true+.
#
# [:on_render_error]
#   Dictates the behavior of exceptions during rendering. Defaults to +:comment+.
#
#   [:ignore]
#     Exceptions are silently ignored.
#   [:comment]
#     Exceptions are rendered inline as comments.
#   [:propagate]
#     Exceptions bubble up to the caller of Inversion::Template#render.
#
#
# [:debugging_comments]
#   Insert various Inversion parse and render statements while rendering. Defaults to +false+.
#
# [:comment_start]
#   When rendering debugging comments, the comment is started with these characters.
#   Defaults to <code>"<!--"</code>.
#
# [:comment_end]
#   When rendering debugging comments, the comment is finished with these characters.
#   Defaults to <code>"-->"</code>.
#
# [:template_paths]
#   An array of filesystem paths to search for templates within, when loaded or
#   included with a relative path.  The current working directory is always the
#   last checked member of this. Defaults to <code>[]</code>.
#
# [:escape_format]
#   The escaping used by tags such as +escape+ and +pp+. Default: +:html+.
#
# [:strip_tag_lines]
#   If a tag's presence introduces a blank line into the output, this option
#   removes it. Defaults to +true+.
#
# [:stat_delay]
#   Templates know when they've been altered on disk, and can dynamically
#   reload themselves in long running applications.  Setting this option creates
#   a purposeful delay between reloads for busy servers. Defaults to +0+
#   (disabled).
#
#
class Inversion::Template
	extend Loggability
	include Inversion::DataUtilities


	# Loggability API -- set up logging through the Inversion module's logger
	log_to :inversion

	# Configurability support -- load template configuration from the 'templates' section
	# of the config.
	if defined?( Configurability )
		extend Configurability
		config_key :templates if respond_to?( :config_key )
	end


	# Load subordinate classes
	require 'inversion/parser'
	require 'inversion/template/node'
	require 'inversion/template/tag'
	require 'inversion/renderstate'

	# Alias to maintain backward compatibility with <0.2.0 code
	Parser = Inversion::Parser

	# Valid actions for 'on_render_error'
	VALID_ERROR_ACTIONS = [
		:ignore,
		:comment,
		:propagate,
	]

	### Default config values
	DEFAULT_CONFIG = {
		# Loading/parsing options
		:ignore_unknown_tags => true,
		:template_paths      => [],
		:stat_delay          => 0,

		# Rendering options
		:on_render_error     => :comment,
		:debugging_comments  => false,
		:comment_start       => '<!-- ',
		:comment_end         => ' -->',
		:escape_format       => :html,
		:strip_tag_lines     => true,
	}.freeze


	##
	# Global config
	class << self; attr_accessor :config; end
	self.config = DEFAULT_CONFIG.dup

	##
	# Global template search path
	class << self; attr_accessor :template_paths; end
	self.template_paths = []


	### Configure the templating system.
	def self::configure( config )
		if config
			Inversion.log.debug "Merging config %p with current config %p" % [ config, self.config ]
			merged_config = DEFAULT_CONFIG.merge( config )
			self.template_paths = Array( merged_config.delete(:template_paths) )
			self.config = merged_config
		else
			defaults = DEFAULT_CONFIG.dup
			self.template_paths = defaults.delete( :template_paths )
			self.config = defaults
		end
	end


	### Read a template object from the specified +path+.
	def self::load( path, parsestate=nil, opts={} )

		# Shift the options hash over if there isn't a parse state
		if parsestate.is_a?( Hash )
			opts = parsestate
			parsestate = nil
		end

		tmpl = nil
		path = Pathname( path )
		opts[:template_paths] ||= self.template_paths
		search_path = opts[:template_paths] + [ Dir.pwd ]
		self.log.debug "Searching template paths: %p" % [ search_path ]

		# Unrestricted template location.
		if path.absolute?
			tmpl = path

		# Template files searched under paths specified in 'template_paths', then
		# the current working directory. First match wins.
		else
			tmpl = search_path.collect {|dir| Pathname(dir) + path }.find do |fullpath|
				fullpath.exist?
			end

			raise RuntimeError, "Unable to find template %p within configured paths %p" %
				[ path.to_s, search_path ] if tmpl.nil?
		end

		# We trust files read from disk
		source = if opts.key?( :encoding )
				tmpl.read( encoding: opts[:encoding] )
			else
				tmpl.read
			end
		source.untaint

		# Load the instance and set the path to the source
		template = self.new( source, parsestate, opts )
		template.source_file = tmpl

		return template
	end


	### Add one or more extension +modules+ to Inversion::Template. This allows tags to decorate
	### the template class with new functionality.
	###
	### Each one of the given +modules+ will be included as a mixin, and if it also
	### contains a constant called ClassMethods and/or PrependedMethods, it will
	### also be extended/prepended (respectively) with it.
	###
	### == Example
	###
	### Add a layout attribute to templates from a 'layout' tag:
	###
	###   class Inversion::Template::LayoutTag < Inversion::Tag
	###
	###     module TemplateExtension
	###
	###       def layout
	###         return @layout || 'default.tmpl'
	###       end
	###
	###       module PrependedMethods
	###         def initialize( * )
	###           super
	###           @layout = nil
	###         end
	###     end
	###
	###     Inversion::Template.add_extensions( TemplateExtension )
	###
	###     # ... more tag stuff
	###
	###   end
	###
	def self::add_extensions( *modules )
		self.log.info "Adding extensions to %p: %p" % [ self, modules ]

		modules.each do |mod|
			include( mod )
			if mod.const_defined?( :ClassMethods )
				submod = mod.const_get( :ClassMethods )
				extend( submod )
			end
			if mod.const_defined?( :PrependedMethods )
				submod = mod.const_get( :PrependedMethods )
				prepend( submod )
			end
		end

	end


	### Create a new Inversion:Template with the given +source+.
	def initialize( source, parsestate=nil, opts={} )
		if parsestate.is_a?( Hash )
			# self.log.debug "Shifting template options: %p" % [ parsestate ]
			opts = parsestate
			parsestate = nil
		else
			self.log.debug "Parse state is: %p" % [ parsestate ]
		end

		@source       = source
		@node_tree    = [] # Parser expects this to always be an Array
		@options      = self.class.config.merge( opts )
		@attributes   = {}
		@fragments    = {}
		@source_file  = nil
		@created_at   = Time.now
		@last_checked = @created_at

		self.parse( source, parsestate )
	end


	### Copy constructor -- make copies of some internal data structures, too.
	def initialize_copy( other )
		@options    = deep_copy( other.options )
		@attributes = deep_copy( other.attributes )
		@fragments  = deep_copy( other.fragments )
	end


	######
	public
	######

	# The raw template source from which the object was parsed.
	attr_reader :source

	# The Pathname of the file the source was read from
	attr_accessor :source_file

	# The Hash of template attributes
	attr_reader :attributes

	# The Hash of rendered template fragments
	attr_reader :fragments

	# The Template's configuration options hash
	attr_reader :options

	# The node tree parsed from the template source
	attr_reader :node_tree


	### If the template was loaded from a file, reload and reparse it from the same file.
	def reload
		file = self.source_file or
			raise Inversion::Error, "template was not loaded from a file"

		self.log.debug "Reloading from %s" % [ file ]
		source = file.read
		self.parse( source )
	end


	### Returns +true+ if the template was loaded from a file and the file's mtime
	### is after the time the template was created.
	def changed?
		return false unless file = self.source_file
		now = Time.now

		if now > ( @last_checked + self.options[ :stat_delay ].to_i )
			if file.mtime > @last_checked
				@last_checked = now
				return true
			end
		end
		return false
	end


	### Render the template, optionally passing a render state (if, for example, the
	### template is being rendered inside another template).
	def render( parentstate=nil, &block )
		self.log.info "rendering template %#x" % [ self.object_id/2 ]
		opts = self.options
		opts.merge!( parentstate.options ) if parentstate

		self.fragments.clear

		state = Inversion::RenderState.new( parentstate, self.attributes, opts, &block )

		# self.log.debug "  rendering node tree: %p" % [ @node_tree ]
		self.walk_tree {|node| state << node }
		self.log.info "  done rendering template %#x: %0.4fs" %
			[ self.object_id/2, state.time_elapsed ]

		if parentstate
			parentstate.fragments.merge!( state.fragments )
		else
			self.fragments.replace( state.rendered_fragments )
		end

		return state.to_s
	end
	alias_method :to_s, :render


	### Return a human-readable representation of the template object suitable
	### for debugging.
	def inspect
		nodemap = if $DEBUG
				", node_tree: %p" % [ self.node_tree.map(&:as_comment_body) ]
			else
				''
			end

		return "#<%s:%08x (loaded from %s) attributes: %p, options: %p%s>" % [
			self.class.name,
			self.object_id / 2,
			self.source_file ? self.source_file : "memory",
			self.attributes.keys,
			self.options,
			nodemap
		]
	end


	#########
	protected
	#########

	### Proxy method: handle attribute readers/writers for attributes that aren't yet
	### defined.
	def method_missing( sym, *args, &block )
		return super unless sym.to_s =~ /^([a-z]\w+)=?$/i
		attribute = $1
		self.install_accessors( attribute )

		# Call the new method via #method to avoid a method_missing loop.
		return self.method( sym ).call( *args, &block )
	end


	### Parse the given +source+ into the template node tree.
	def parse( source, parsestate=nil )
		opts = self.class.config.merge( self.options )
		parser = Inversion::Parser.new( self, opts )

		@attributes.clear
		@node_tree = parser.parse( source, parsestate )
		@source = source

		self.define_attribute_accessors
	end


	### Walk the template's node tree, yielding each node in turn to the given block.
	def walk_tree( nodes=@node_tree, &block )
		nodes.each do |node|
			yield( node )
		end
	end


	### Search for identifiers in the template's node tree and declare an accessor
	### for each one that's found.
	def define_attribute_accessors
		self.walk_tree do |node|
			self.add_attributes_from_node( node )
		end

		self.attributes.each do |key, _|
			self.install_accessors( key )
		end
	end


	### Add attributes for the given +node+'s identifiers.
	def add_attributes_from_node( node )
		if node.respond_to?( :identifiers )
			node.identifiers.each do |id|
				next if @attributes.key?( id.to_sym )
				@attributes[ id.to_sym ] = nil
			end
		end
	end


	### Install reader and writer methods for the attribute associated with the specified +key+.
	def install_accessors( key )
		reader, writer = self.make_attribute_accessors( key )

		self.singleton_class.send( :define_method, key, &reader )
		self.singleton_class.send( :define_method, "#{key}=", &writer )
	end


	### Make method bodies
	def make_attribute_accessors( key )
		key = key.to_sym
		reader = lambda { self.attributes[key] }
		writer = lambda {|newval| self.attributes[key] = newval }

		return reader, writer
	end
end # class Inversion::Template

