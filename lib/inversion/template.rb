# vim: set noet nosta sw=4 ts=4 :

require 'inversion' unless defined?( Inversion )

# The main template class. Instances of this class are created by parsing template
# source and combining the resulting node tree with a set of attributes that
# can be used to populate it when rendered.
#
# @author Michael Granger <ged@FaerieMUD.org>
# @author Mahlon E. Smith <mahlon@martini.nu>
#
class Inversion::Template
	include Inversion::Loggable

	require 'inversion/template/parser'


	### Read a template object from the specified +path+.
	### @param [String] path  the path to the template
	### @return [Inversion::Template]
	def self::load( path )
		File.open( path, 'r' ) do |io|
			return self.new( io )
		end
	end



	### Create a new Inversion:Template with the given +source+.
	### @param [String, #read]  source  the template source, which can either be a String or
	###                                 an object that can be #read from.
	### @return [Inversion::Template]   the new template
	def initialize( source )
		source      = source.read if source.respond_to?( :read )
		@source     = source
		@parser     = Inversion::Template::Parser.new
		@tree       = @parser.parse( source )

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


	### Render the template.
	### @return [String] the rendered template content
	def render
		output = ''

		self.walk_tree do |node|
			output << node.render( self )
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

