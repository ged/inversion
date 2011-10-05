#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'pathname'
require 'inversion' unless defined?( Inversion )

# Load the Configurability library if it's installed
begin
	require 'configurability'
	require 'configurability/config'
rescue LoadError
end


# The main template class. Instances of this class are created by parsing template
# source and combining the resulting node tree with a set of attributes that
# can be used to populate it when rendered.
class Inversion::Template
	include Inversion::Loggable

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
		:ignore_unknown_tags => true,
		:on_render_error     => :comment,
		:debugging_comments  => false,
		:comment_start       => '<!-- ',
		:comment_end         => ' -->',
		:template_paths      => [],
		:escape_format       => :html,
		:strip_tag_lines     => true,
	}


	### Global config
	@config = DEFAULT_CONFIG.dup
	class << self; attr_accessor :config; end


	### Configure the templating system.
	def self::configure( config )
		Inversion.log.debug "Merging config %p with current config %p" % [ config, self.config ]
		self.config = self.config.merge( config )
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
		template_paths = Array( self.config[:template_paths] ) + [ Dir.pwd ]

		# Unrestricted template location.
		if path.absolute?
			tmpl = path

		# Template files searched under paths specified in 'template_paths', then
		# the current working directory. First match wins.
		else
			tmpl = template_paths.collect {|dir| Pathname(dir) + path }.find do |fullpath|
				fullpath.exist?
			end

			raise RuntimeError, "Unable to find template %p within configured paths %p" %
				[ path.to_s, template_paths ] if tmpl.nil?
		end

		# We trust files read from disk
		source = tmpl.read
		source.untaint

		# Load the instance and set the path to the source
		template = self.new( source, parsestate, opts )
		template.source_file = tmpl

		return template
	end


	### Create a new Inversion:Template with the given +source+.
	def initialize( source, parsestate=nil, opts={} )
		if parsestate.is_a?( Hash )
			self.log.debug "Shifting template options: %p" % [ parsestate ]
			opts = parsestate
			parsestate = nil
		else
			self.log.debug "Parse state is: %p" % [ parsestate ]
		end

		@source       = source
		@parser       = Inversion::Parser.new( self, opts )
		@node_tree    = [] # Parser expects this to always be an Array
		@init_options = opts
		@options      = nil
		@attributes   = {}
		@source_file  = nil
		@created_at   = Time.now

		self.parse( source, parsestate )
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
		return ( file.mtime > @created_at )
	end


	### Render the template, optionally passing a render state (if, for example, the
	### template is being rendered inside another template).
	def render( parentstate=nil, &block )
		self.log.info "rendering template 0x%08x" % [ self.object_id/2 ]
		state = Inversion::RenderState.new( parentstate, self.attributes, self.options, &block )

		# Pre-render hook
		self.walk_tree {|node| node.before_rendering(state) }

		# self.log.debug "  rendering node tree: %p" % [ @node_tree ]
		self.walk_tree {|node| state << node }

		# Post-render hook
		self.walk_tree {|node| node.after_rendering(state) }

		self.log.info "  done rendering template 0x%08x: %0.4fs" %
			[ self.object_id/2, state.time_elapsed ]

		return state.to_s
	end
	alias_method :to_s, :render


	### Return a human-readable representation of the template object suitable
	### for debugging.
	def inspect
		return "#<%s:%08x (loaded from %s) attributes: %p, node_tree: %p, options: %p>" % [
			self.class.name,
			self.object_id / 2,
			self.source_file ? self.source_file : "memory",
			self.attributes,
			self.node_tree.map(&:as_comment_body),
			self.options,
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
		@options = self.class.config.merge( @init_options )
		@attributes.clear
		@node_tree = @parser.parse( source, parsestate )
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

