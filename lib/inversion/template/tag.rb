#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion' unless defined?( Inversion )
require 'inversion/template' unless defined?( Inversion::Template )

require 'inversion/template/node'
require 'inversion/mixins'

# Inversion template tag node base class. Represents a directive in a template
# that defines behavior and/or state.
# 
# This class supports the RubyGems plugin API: to provide one or more Inversion tags
# in a gem of your own, put them into a directory named 'inversion/template' and
# name the files <tt><tagname>tag.rb</tt> and the classes <tagname.capitalize>Tag.
class Inversion::Template::Tag < Inversion::Template::Node
	include Inversion::Loggable,
	        Inversion::AbstractClass


	# The glob pattern for matching template tag plugins
	TAG_PLUGIN_PATTERN = 'inversion/template/*tag.rb'


	########################################################################
	### C L A S S   M E T H O D S
	########################################################################

	# The hash of loaded tag types
	@types = nil

	# Derivatives of this class
	@derivatives = []

	class << self
		attr_reader :types, :derivatives
	end


	### Inheritance hook -- keep track of loaded derivatives.
	def self::inherited( subclass )
		# Inversion.log.debug "%p inherited from %p" % [ subclass, self ]
		Inversion::Template::Tag.derivatives << subclass 
		super
	end


	### Return a Hash of all loaded tag types, loading them if they haven't been loaded already.
	def self::types
        self.load_all unless @types
        return @types
	end


	### Load all available template tags and return them as a Hash keyed by their name.
	def self::load_all
		tags = {}

		Gem.find_files( TAG_PLUGIN_PATTERN ).each do |tagfile|
			tagname = tagfile[ %r{/(\w+)tag\.rb$}, 1 ].untaint

			Inversion.log.debug "Loading tag type %p from %p" % [ tagname, tagfile ]
			self.load( tagfile )

			# Inversion.log.debug "Looking for class for %p tag" % [ tagname ]
			tagclass = self.derivatives.find do |derivclass|
				if derivclass.name.nil? || derivclass.name.empty?
					# Inversion.log.debug "  skipping anonymous class %p" % [ derivclass ]
					nil
				elsif !derivclass.respond_to?( :new )
					# Inversion.log.debug "  skipping abstract class %p" % [ derivclass ]
					nil
				else
					derivclass.name.downcase =~ /\b#{tagname}tag$/
				end
			end

			unless tagclass
				Inversion.log.debug "  no class found for %p tag" % [ tagname ]
				next
			end

			Inversion.log.debug "  found: %p" % [ tagclass ]
			tags[ tagname.to_sym ] = tagclass
		end

		@types ||= {}
		@types.merge!( tags )

		return @types
	end


	### Safely load the specified +tagfile+.
	def self::load( tagfile )
		require( tagfile )
	rescue => err
		Inversion.log.error "%s while loading tag plugin %p: %s" %
			[ err.class.name, tagfile, err.message ]
		Inversion.log.debug "  " + err.backtrace.join( "\n  " )
		return false
	end


	### Create a new Inversion::Template::Tag from the specified +tagname+ and +body+.
	def self::create( tagname, body, linenum=nil, colnum=nil )
		tagname =~ /^(\w+)$/i or raise ArgumentError, "invalid tag name %p" % [ tagname ]
		tagtype = $1.downcase.untaint

		unless tagclass = self.types[ tagtype.to_sym ]
			Inversion.log.warn "Unknown tag type %p; registered: %p" %
				[ tagtype, self.types.keys ]
			return nil
		end

		return tagclass.new( body, linenum, colnum )
	end


	########################################################################
	### I N S T A N C E   M E T H O D S
	########################################################################

	### Create a new Inversion::Template::Tag with the specified +body+.
	def initialize( body, linenum=nil, colnum=nil )
		super
		@body = body.to_s.strip
	end


	######
	public
	######

	# the body of the tag
	attr_reader :body


	### Render the tag as the body of a comment, suitable for template debugging.
	def as_comment_body
		return "%s %s at %s" % [ self.tagname, self.body.to_s.dump, self.location ]
	end


	### Return the human-readable name of the tag class
	def tagname
		return self.class.name.sub(/Tag$/, '').sub( /^.*::/, '' )
	end

end # class Inversion::Template::Tag

