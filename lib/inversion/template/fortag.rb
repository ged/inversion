#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/codetag'


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
	include Inversion::Loggable

	# <?for var in attribute ?>
	tag_pattern 'kw sp $(ident) sp $(kw) sp $( .+ )' do |tag, match|
		raise Inversion::ParseError, "invalid keyword: expected 'in', got %p for %p" %
			[ match.string(2), tag.body ] unless match.string(2) == 'in'

		tag.block_args << match.string( 1 ).untaint.to_sym
		tag.enumerator = match.string( 3 )
	end


	# <?for var1, var2, var3 in attribute.methodchain ?>
	tag_pattern 'kw sp $(ident (comma sp? ident)+) sp $(kw) sp $( .+ )' do |tag, match|
		raise Inversion::ParseError, "invalid keyword: expected 'in', got %p for %p" %
			[ match.string(2), tag.body ] unless match.string(2) == 'in'

		tag.block_args += match.string( 1 ).untaint.split(/,\s?/).map( &:to_sym )
		tag.enumerator = match.string( 3 )
	end



	### Create a new ForTag with the specified +body+.
	def initialize( body )
		@block_args = []
		@enumerator = nil

		super( 'for ' + body )
	end


	######
	public
	######

	# The array of attribute names that will be assigned to the rendering scope
	# by the block for each iteration
	attr_accessor :block_args

	# The attribute or methodchain that yields the enumerable object
	attr_accessor :enumerator


end # class Inversion::Template::ForTag

