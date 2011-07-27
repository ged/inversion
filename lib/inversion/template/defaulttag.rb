#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/codetag'

# Inversion 'default' tag.
#
# The default tag sets the default value of an attribute to a constant, the value of
# another attribute, or the results of evaluating a methodchain on an attribute.
#
# == Syntax
#   <!-- Set a default width that can be overridden by the controller -->
#   <?default width to 120 ?>
#   <?default employees to [] ?>
#
#   <!-- Default an attribute to the value of a second attribute -->
#   <?default content to body ?>
#
#   <!-- Set the title to the employee's name if it hasn't been set explicitly -->
#   <?default title to "%s, %s" % [ employee.lastname, employee.firstname ] ?>
#
class Inversion::Template::DefaultTag < Inversion::Template::CodeTag

	# <?default «identifier» to "%s" % foo ?>
	tag_pattern '$(ident) sp $(ident) sp tstring_beg $(tstring_content) tstring_end sp* $(op) sp* $( .* )' do |tag, match|
		op = match.string( 4 )
		raise Inversion::ParseError, "expected '%%', got %p instead" % [ op ] unless op == '%'
		raise Inversion::ParseError, "invalid operator: expected 'to', got %p for %p" %
			[ match.string(2), tag.body ] unless match.string(2) == 'to'

		tag.name    = match.string( 1 )
		tag.format  = match.string( 3 )
		tag.literal = match.string( 5 )
	end

	# <?default «identifer» to «identifier».«methodchain» ?>
	tag_pattern "$(ident) sp $(ident) sp $(ident) $( .* )" do |tag, match|
		raise Inversion::ParseError, "invalid operator: expected 'to', got %p for %p" %
			[ match.string(2), tag.body ] unless match.string(2) == 'to'

		tag.name        = match.string( 1 )
		tag.identifiers << match.string( 3 )
		tag.methodchain = match.string( 4 )
	end

	# <?default «identifer» to «literal» ?>
	tag_pattern "$(ident) sp $(ident) sp $( .* )" do |tag, match|
		raise Inversion::ParseError, "invalid operator: expected 'to', got %p for %p" %
			[ match.string(2), tag.body ] unless match.string(2) == 'to'

		tag.name    = match.string( 1 )
		tag.literal = match.string( 3 )
	end


	### Create a new DefaultTag with the given +name+, which should be a valid
	### Ruby identifier.
	def initialize( body, linenum=nil, colnum=nil )
		@name        = nil
		@methodchain = nil
		@literal     = nil
		@format      = nil

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

	# The literal, if the tag had one (as opposed to an attribute or methodchain)
	attr_accessor :literal

	# the chain of methods that should be called (if any).
	attr_accessor :methodchain


	### Render the tag as the body of a comment, suitable for template debugging.
	def as_comment_body
		comment = "%s '%s': { " % [ self.tagname, self.name ]
		if self.methodchain
			comment << "template.%s%s" % [ self.identifiers.first, self.methodchain ]
		else
			comment << self.literal
		end
		comment << " }"
		comment << " with format: %p" % [ self.format ] if self.format

		return comment
	end


	### Set the specified value (if it's nil) before rendering.
	def before_rendering( renderstate )
		if val = renderstate.attributes[ self.name.to_sym ]
			self.log.info "Not defaulting %s: already set to %p" %
				[ self.name, val ]
			return nil
		end

		default = nil
		if chain = self.methodchain
			self.log.debug "Using methodchain %p to set default for %p" %
				[ chain, self.name ]
			default = renderstate.eval( 'self' + '.' + self.identifiers.first + chain )
		else
			self.log.debug "Using literal %p to set default for %p" %
				[ self.literal, self.name ]
			default = renderstate.eval( self.literal )
			default = self.format % default if self.format
		end

		self.log.debug "  default value: %p" % [ default ]
		renderstate.attributes[ self.name.to_sym ] = default
	end


	### Render as the empty string.
	def render( renderstate )
		return ''
	end

end # class Inversion::Template::DefaultTag

