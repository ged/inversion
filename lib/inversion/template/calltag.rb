#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/codetag'

# Inversion call tag.
#
# Call tags insert the results of a method call applied to all the members of
# the template identifier.
#
# == Syntax
#
#   <?call foo.bar ?>
#   <?call "%0.2f" % foo.bar ?>
#
class Inversion::Template::CallTag < Inversion::Template::CodeTag

	tag_pattern '$(ident) period $(ident)' do |tag, match|
		tag.attribute = match.string( 1 )
		tag.methodchain << [ match.string(2) ]
	end

	tag_pattern '$(ident) period $(ident) lparen (.*?) rparen' do |tag, match|
		tag.attribute = match.string( 1 )
		tag.methodchain << [ match.string(2), match.string(3).strip ]
	end



	### Parse a new CodeTag from the given +code+.
	def initialize( code )
		@attribute = nil
		@methodchain = []
		@format = nil

		super

		self.identifiers << self.attribute.untaint.to_sym
		# :TODO: Add identifiers for the methodchain, too.
	end


	######
	public
	######

	# @return [String]  the name of the attribute 
	attr_accessor :attribute

	# @return [String]  the format string used to format the attribute in the template (if 
	# one was declared)
	attr_accessor :format

	# @return [Array<String>]  the chain of methods that should be called.
	attr_accessor :methodchain


end # class Inversion::Template::CallTag

