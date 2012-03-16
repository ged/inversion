#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/tag'

# Inversion import tag.
#
# The import tag copies one or more attributes from an enclosing template so they
# only need to be set once.
#
# == Syntax
#
#   <?import txn ?>
#   <?import foo, bar ?>
#
class Inversion::Template::ImportTag < Inversion::Template::Tag

	### Create a new ImportTag with the given +name+, which should be a valid
	### Ruby identifier.
	def initialize( body, linenum=nil, colnum=nil )
		super
		@attributes = body.split( /\s*,\s*/ ).collect {|name| name.untaint.strip.to_sym }
	end


	######
	public
	######

	# the names of the attributes to import
	attr_reader :attributes


	### Merge the inherited renderstate into the current template's +renderstate+.
	def render( renderstate )
		if (( cstate = renderstate.containerstate ))
			# self.log.debug "Importing inherited attributes: %p from %p" %
			#	[ @attributes, cstate.attributes ]

			# Pick out the attributes that are being imported
			inherited_attrs = @attributes.inject( {} ) do |attrs, key|
				attrs[ key ] = cstate.attributes[ key ]
				attrs
			end

			# Merge, but overwrite unset values with inherited ones
			renderstate.attributes.merge!( inherited_attrs ) do |key, oldval, newval|
				if oldval.nil?
					# self.log.debug "Importing attribute %p: %p" % [ key, newval ]
					newval
				else
					# self.log.debug "Not importing attribute %p: already set to %p" % [ key, oldval ]
					oldval
				end
			end

		else
			self.log.debug "No-op import: no parent attributes set."
		end

		return nil
	end


	### Render the tag as the body of a comment, suitable for template debugging.
	def as_comment_body
		return "Import %s" % [ self.attributes.join(', ') ]
	end

end # class Inversion::Template::ImportTag

