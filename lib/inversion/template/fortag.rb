#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/codetag'
require 'inversion/template/containertag'


# Inversion 'for' tag.
#
# Iteration tag for outputting a template part for each member of a collection (i.e.,
# an object that is Enumerable).
#
# == Syntax
#
#   <?for var in attribute ?>
#   <?for var in attribute.methodchain ?>
#   <?for var1, var2 in attribute.methodchain ?>
#
#
# == Examples
#
#    <?for employee in company.employees ?>
#
#    Hey <?call employee.name ?>! You're fired!
#
#    <?end ?>
#
class Inversion::Template::ForTag < Inversion::Template::CodeTag
	include Inversion::Template::ContainerTag

	# <?for var in attribute ?>
	# <?for var in attribute.methodchain ?>
	tag_pattern 'kw sp $(ident) sp $(kw) sp $(ident) $( .* )' do |tag, match|
		raise Inversion::ParseError, "invalid keyword: expected 'in', got %p for %p" %
			[ match.string(2), tag.body ] unless match.string(2) == 'in'

		tag.block_args << match.string( 1 ).untaint.to_sym
		tag.identifiers << match.string( 3 ).untaint.to_sym

		tag.enumerator = match.string( 3 )
		tag.enumerator << match.string( 4 ) if match.string( 4 )
	end


	# <?for var1, var2, var3 in attribute ?>
	# <?for var1, var2, var3 in attribute.methodchain ?>
	tag_pattern 'kw sp $(ident (comma sp? ident)+) sp $(kw) sp $(ident) $( .* )' do |tag, match|
		raise Inversion::ParseError, "invalid keyword: expected 'in', got %p for %p" %
			[ match.string(2), tag.body ] unless match.string(2) == 'in'

		tag.block_args += match.string( 1 ).untaint.split(/,\s?/).map( &:to_sym )
		tag.identifiers << match.string( 3 ).untaint.to_sym

		tag.enumerator = match.string( 3 )
		tag.enumerator << match.string( 4 ) if match.string( 4 )
	end



	### Create a new ForTag with the specified +body+.
	def initialize( body, linenum=nil, colnum=nil )
		@block_args = []
		@enumerator = nil

		super( 'for ' + body, linenum, colnum )
	end


	######
	public
	######

	# The array of attribute names that will be assigned to the rendering scope
	# by the block for each iteration
	attr_accessor :block_args

	# The attribute or methodchain that yields the enumerable object
	attr_accessor :enumerator


	### Iterate over the enumerator in +state+ and render the tag's
	### contents for each iteration.
	def render( state )
		lvalue = state.eval( self.enumerator ) or return nil
		lvalue = lvalue.each unless lvalue.respond_to?( :next )

		# self.log.debug "Rendering %p via block args: %p" % [ lvalue, self.block_args ]

		# Loop will exit as soon as the Enumerator runs out of elements
		loop do
			args = lvalue.next
			args = [ args ] unless args.is_a?( Array )

			# Turn the block arguments into an overrides hash by zipping up
			# the arguments names and values
			overrides = Hash[ self.block_args.zip(args) ]

			# Overlay the block args from the 'for' over the template attributes and render
			# each subnode
			state.with_attributes( overrides ) do
				super
			end
		end

		return nil
	end


	### Render the tag as the body of a comment, suitable for template debugging.
	def as_comment_body
		comment = "%s: { %s IN template.%s }" % [
			self.tagname,
			self.block_args.join(', '),
			self.enumerator
		]

		return comment
	end

end # class Inversion::Template::ForTag

