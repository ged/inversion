#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template'

# Inversion template tag base class.
class Inversion::Template::Tag

	# The glob pattern for matching template tag plugins
	TAG_PLUGIN_PATTERN = 'inversion/template/*_tag.rb'


	# Derivatives of this class
	@derivatives = []
	class << self
		attr_reader :derivatives
	end


	### Inheritance hook -- keep track of loaded derivatives.
	def self::inherited( subclass )
		@derivatives << subclass
		super
	end


	### Load all available template tags and return them as a Hash keyed by their name.
	### @return [Hash<Symbol => Inversion::Template::Tag]  the tags hash
	def self::load_all
		tags = {}

		Gem.find_files( TAG_PLUGIN_PATTERN ).each do |tagfile|
			tagname = tagfile[ %r{/(\w+)_tag\.rb}, 1 ].untaint
			tagclass = self.load( tagfile ) or next
			tags[ tagname.to_sym ] = tagclass
		end

		return tags
	end


	### Safely load the specified +tagfile+.  Returns the tag +Class+ if it loaded
	### successfully, +false+ on error, and +nil+ if the if no new tag class was defined.
	def self::load( tagfile )
		before_loading = @derivatives.dup
		require( tagfile )
		tagclasses = @derivatives - before_loading

		return tagclasses.first
	rescue => err
		Inversion.log.error "%s while loading tag plugin %p: %s" %
			[ err.class.name, tagname, err.message ]
		Inversion.log.debug "  " + err.backtrace.join( "\n  " )
		return false
	end
end # class Inversion::Template::Tag

