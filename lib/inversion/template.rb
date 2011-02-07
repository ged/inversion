#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion'
require 'ripper'
require 'nokogiri'

# FIX (top-level documentation)
#
# @author Michael Granger <ged@FaerieMUD.org>
# @author Mahlon E. Smith <mahlon@martini.nu>
#
class Inversion::Template

	# The hash of loaded tag types
	@tag_types = nil


	### Return a Hash of all loaded tag types, loading them if they haven't been loaded already.
	### @return [Hash<Symbol => Inversion::Template::Tag>] the hash of tags
	def self::tag_types
		@tag_types ||= Inversion::Template::Tag.load_all
		return @tag_types
	end


	### Create a new Inversion:Template with the given +source+.
	### @param [String, #read]  source  the template source, which can either be a String or
	###                                 an object that can be #read from.
	### @return [Inversion::Template]   the new template
	def initialize( source )
		source  = source.read if source.respond_to?( :read )
		@source = source
	end


	######
	public
	######

	### @return [String] the raw template source
	attr_reader :source


	### Render the template.
	### @return [String] the rendered template content
	def render
		return self.source
	end

end # class Inversion::Template

