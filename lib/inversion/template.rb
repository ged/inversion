#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

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
#
# @author Michael Granger <ged@FaerieMUD.org>
# @author Mahlon E. Smith <mahlon@martini.nu>
#
class Inversion::Template
	include Inversion::Loggable

	# Configurability support -- load template configuration from the 'templates' section
	# of the config.
	if defined?( Configurability )
		extend Configurability 
		config_key :templates if respond_to?( :config_key )
	end


	# Load subordinate classes
	require 'inversion/template/parser'
	require 'inversion/template/node'
	require 'inversion/template/tag'
	require 'inversion/renderstate'


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
	}


	### Global config
	@config = DEFAULT_CONFIG.dup
	class << self; attr_accessor :config; end


	### Configure the templating system.
	### @param [#[]] config  the configuration values
	### @option config [boolean] :raise_on_unknown    (false) Raise an exception on unknown tags.
	### @option config [boolean] :debugging_comments  (false) Render a comment into output for each 
	###    node.
	### @option config [String] :comment_start        ('<!-- ') Characters to use to start a comment.
	### @option config [String] :comment_end          (' -->') Characters to use to close a comment.
	def self::configure( config )
		Inversion.log.debug "Merging config %p with current config %p" % [ config, self.config ]
		self.config = self.config.merge( config )
	end


	### Read a template object from the specified +path+.
	### @param [String] path  the path to the template
	### @return [Inversion::Template]
	def self::load( path )
		source = IO.read( path )
		source.untaint
		return self.new( source )
	end



	### Create a new Inversion:Template with the given +source+.
	### @param [String, #read]  source  the template source, which can either be a String or
	###                                 an object that can be #read from.
	### @param [#[]] opts               overrides of the global template options; @see ::configure
	### @return [Inversion::Template]   the new template
	def initialize( source, opts={} )
		@source     = source
		@parser     = Inversion::Template::Parser.new( opts )
		@tree       = @parser.parse( source )
		@options    = self.class.config.merge( opts )

		@attributes = {}

		self.define_attribute_accessors
	end



	######
	public
	######

	### @return [String] the raw template source
	attr_reader :source

	### @return [Hash] the hash of attributes added by template directives
	attr_reader :attributes

	### @return [Array] the array of Inversion::Template::Node objects
	attr_reader :tree

	### @return [Hash] the Hash of configuration options
	attr_reader :options


	### Render the template.
	### @return [String] the rendered template content
	def render
		output = ''
		state = Inversion::RenderState.new( self.attributes, self.options )

		self.log.debug "Rendering node tree: %p" % [ @tree ]
		self.walk_tree do |node|
			output << state.make_node_comment( node )

			begin
				output << node.render( state )
			rescue => err
				output << state.handle_render_error( node, err )
			end
		end

		return output
	end


	#########
	protected
	#########

	### Search for identifiers in the template's node tree and declare an accessor
	### for each one that's found.
	def define_attribute_accessors
		self.walk_tree do |node|
			self.add_attributes_from_node( node )
		end

		self.attributes.each do |key, _|
			reader, writer = self.make_attribute_accessors( key )

			self.singleton_class.send( :define_method, key, &reader )
			self.singleton_class.send( :define_method, "#{key}=", &writer )
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


	### Walk the template's node tree, yielding each node in turn to the given block.
	def walk_tree( nodes=@tree, &block )
		nodes.each do |node|
			yield( node )
		end
	end


	### Make method bodies
	def make_attribute_accessors( key )
		reader = lambda { self.attributes[key] }
		writer = lambda {|newval| self.attributes[key] = newval }

		return reader, writer
	end
end # class Inversion::Template

