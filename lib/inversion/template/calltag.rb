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

class Inversion::Template::CallTag < Inversion::Template::CodeTag

	tag_pattern '$(ident) $( .+ )' do |tag, match|
		tag.attribute = match.string( 1 ).untaint.to_sym
		tag.methodchain = match.string( 2 )
	end


	########################################################################
	### I N S T A N C E   M E T H O D S
	########################################################################

	### Parse a new CodeTag from the given +code+.
	### @param [String] code  ruby code to be evaluated
	### @param [Integer] linenum the line number the tag was parsed from
	### @param [Integer] colnum  the column number the tag was parsed from
	def initialize( body, linenum=nil, colnum=nil )
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

	# @return [Symbol]  the name of the attribute 
	attr_accessor :attribute

	# @return [String]  the format string used to format the attribute in the template (if 
	# one was declared)
	attr_accessor :format

	# @return [Array<String>]  the chain of methods that should be called.
	attr_accessor :methodchain


	### Render the method chains against the attributes of the specified +render_state+ 
	### and return them.
	def render( render_state=nil )
		return '' if render_state.nil?

		attribute = render_state.attributes[ self.attribute ]
		unless attribute.respond_to?( :get_binding )
			def attribute.get_binding; binding(); end
		end

		methodchain = "self" + self.methodchain
		self.log.debug "Evaling methodchain: %p on: %p" % [ methodchain, attribute ]
		result = eval( methodchain, attribute.get_binding )

		return result
	end


	### Render the tag as the body of a comment, suitable for template debugging.
	### @return [String]  the tag as the body of a comment
	def as_comment_body
		tagname = self.class.name.sub(/Tag$/, '').sub( /^.*::/, '' )
		return "%s: { template.attributes[ :%s ]%s }" %
			[ tagname, self.attribute, self.methodchain ]
	end


end # class Inversion::Template::CallTag

