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

	# <?attr foo ?>
	tag_pattern '$(ident)' do |tag, match|
		tag.send( :log ).debug "  Identifier is: %p" % [ match.string(1) ]
		tag.name = match.string( 1 )
	end

	# <?attr "%s" % foo ?>
	tag_pattern 'tstring_beg $(tstring_content) tstring_end sp* $(op) sp* $(ident)' do |tag, match|
		op = match.string( 2 )
		raise Inversion::ParseError, "expected '%%', got %p instead" % [ op ] unless op == '%'

		tag.format = match.string( 1 )
		tag.name   = match.string( 3 )
	end

	# <?attr foo.methodchain ?>
	tag_pattern '$(ident) $( .+ )' do |tag, match|
		tag.name = match.string( 1 ).untaint.to_sym
		tag.methodchain = match.string( 2 )
	end



	### Create a new AttrTag with the given +name+, which should be a valid
	### Ruby identifier.
	### @param [String] name  the name of the attribute to declare in the template
	### @param [Integer] linenum the line number the tag was parsed from
	### @param [Integer] colnum  the column number the tag was parsed from
	### @return [Inversion::Template::AttrTag]  the resulting tag object.
	def initialize( body, linenum=nil, colnum=nil )
		@name        = nil
		@format      = nil
		@methodchain = nil
		@format      = nil

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

	# @return [String]  the chain of methods that should be called (if any).
	attr_accessor :methodchain


	### Render the tag attributes of the specified +render_state+ and return them.
	def render( render_state=nil )
		return nil if render_state.nil?

		value     = nil
		attribute = render_state.attributes[ self.name.to_sym ]

		# Evaluate the method chain (if there is one) against the attribute
		if self.methodchain
			methodchain = "self" + self.methodchain
			self.log.debug "Evaling methodchain: %p on: %p" % [ methodchain, attribute ]
			value = attribute.instance_eval( methodchain )
		else
			value = attribute
		end

		return value unless value

		# Apply the format if there is one
		if self.format
			return self.format % value
		else
			return value
		end
	end


	### Render the tag as the body of a comment, suitable for template debugging.
	### @return [String]  the tag as the body of a comment
	def as_comment_body
		comment = "%s: { template.%s" % [ self.tagname, self.name ]
		comment << self.methodchain if self.methodchain
		comment << " }"
		comment << " with format: %p" % [ self.format ] if self.format

		return comment
	end

end # class Inversion::Template::AttrTag

