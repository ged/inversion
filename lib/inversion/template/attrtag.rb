#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/codetag'

# Inversion attribute tag.
#
# Attribute tags add an accessor to a template like 'attr_accessor' does for Ruby classes.
#
# == Syntax
#
#   <?attr foo ?>
#   <?attr "%0.2f" % foo ?>
#
class Inversion::Template::AttrTag < Inversion::Template::CodeTag

	tag_pattern '$(ident)' do |tag, match|
		tag.send( :log ).debug "  Identifier is: %p" % [ match.string(1) ]
		tag.name = match.string( 1 )
	end

	tag_pattern 'tstring_beg $(tstring_content) tstring_end sp* $(op) sp* $(ident)' do |tag, match|
		op = match.string( 2 )
		raise Inversion::ParseError, "expected '%%', got %p instead" % [ op ] unless op == '%'

		tag.format = match.string( 1 )
		tag.name   = match.string( 3 )
	end


	### Create a new AttrTag with the given +name+, which should be a valid
	### Ruby identifier.
	### @param [String] name  the name of the attribute to declare in the template
	def initialize( code )
		@name   = nil
		@format = nil

		super

		# Add an identifier for the tag name
		self.identifiers << self.name.untaint.to_sym
	end


	######
	public
	######

	# @return [String]  the name of the attribute
	attr_accessor :name

	# @return [String]  the format string used to format the attribute in the template (if
	# one was declared)
	attr_accessor :format


	### Render the tag attributes of the specified +template+ and return them.
	def render( template=nil )
		return '' if template.nil?
		value = template.attributes[ self.name.to_sym ] or return ''

		if self.format
			return self.format % value
		else
			return value.to_s
		end
	end


	### Render the tag as the body of a comment, suitable for template debugging.
	### @return [String]  the tag as the body of a comment
	def as_comment_body
		comment = super
		comment << " with format: %p" % [ self.format ] if self.format

		return comment
	end

end # class Inversion::Template::AttrTag

