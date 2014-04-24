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
		tag.name = match.string( 1 ).untaint.to_sym
	end

	# <?attr "%s" % foo ?>
	tag_pattern 'tstring_beg $(tstring_content) tstring_end sp* $(op) sp* $(ident)' do |tag, match|
		op = match.string( 2 )
		raise Inversion::ParseError, "expected '%%', got %p instead" % [ op ] unless op == '%'

		tag.format = match.string( 1 )
		tag.name   = match.string( 3 ).untaint.to_sym
	end

	# <?attr foo.methodchain ?>
	tag_pattern '$(ident) $( .+ )' do |tag, match|
		tag.name = match.string( 1 ).untaint.to_sym
		tag.methodchain = match.string( 2 )
	end

	# <?attr "%s" % foo.methodchain ?>
	tag_pattern 'tstring_beg $(tstring_content) tstring_end sp* $(op) sp* $(ident) $( .+ )' do |tag, match|
		op = match.string( 2 )
		raise Inversion::ParseError, "expected '%%', got %p instead" % [ op ] unless op == '%'

		tag.format      = match.string( 1 )
		tag.name        = match.string( 3 ).untaint.to_sym
		tag.methodchain = match.string( 4 )
	end



	### Create a new AttrTag with the given +name+, which should be a valid
	### Ruby identifier. The +linenum+ and +colnum+ should be the line and column of
	### the tag in the template source, if available.
	def initialize( body, linenum=nil, colnum=nil )
		@name        = nil
		@format      = nil
		@methodchain = nil

		super

		# Add an identifier for the tag name
		self.identifiers << self.name.untaint.to_sym
	end


	######
	public
	######

	# the name of the attribute
	attr_accessor :name

	# the format string used to format the attribute in the template (if
	# one was declared)
	attr_accessor :format

	# the chain of methods that should be called (if any).
	attr_accessor :methodchain


	### Render the tag attributes of the specified +renderstate+ and return them.
	def render( renderstate )
		value = self.evaluate( renderstate ) # :FIXME: or return value # nil or false?

		# Apply the format if there is one
		if self.format && value
			return self.format % value
		else
			return value
		end
	end


	### Evaluate the body of the tag in the context of +renderstate+ and return the results.
	def evaluate( renderstate )
		code = [ self.name.to_s, self.methodchain ].join( '' )
		return renderstate.eval( code )
	end


	### Render the tag as the body of a comment, suitable for template debugging.
	def as_comment_body
		comment = "%s: { template.%s" % [ self.tagname, self.name ]
		comment << self.methodchain if self.methodchain
		comment << " }"
		comment << " with format: %p" % [ self.format ] if self.format

		return comment
	end

end # class Inversion::Template::AttrTag

