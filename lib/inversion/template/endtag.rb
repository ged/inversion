#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion' unless defined?( Inversion )
require 'inversion/template' unless defined?( Inversion::Template )
require 'inversion/template/tag' unless defined?( Inversion::Template::Tag )

# Closing tag class
class Inversion::Template::EndTag < Inversion::Template::Tag

	### Overridden to provide a default +body+.
	def initialize( body='', linenum=nil, colnum=nil )
		super
		@opener = nil
	end


	######
	public
	######

	# The ContainerTag that this end tag closes
	attr_reader :opener


	### Parser callback -- close the given +state+'s currently-open container node.
	def before_appending( state )
		@opener = state.pop
		self.log.debug "End tag for %s at %s" % [ @opener.tagname, @opener.location ]

		# If the end tag has a body, it should match the container that's just
		# been popped.
		if self.body &&
			!self.body.empty? &&
			self.body.downcase != @opener.tagname.downcase

			raise Inversion::ParseError, "unbalanced end: expected %p, got %p" % [
				@opener.tagname.downcase,
				self.body.downcase,
			]
		end

		super
	end


	### Render the tag as the body of a comment, suitable for template debugging.
	def as_comment_body
		return "End of %s" % [ self.opener.as_comment_body ]
	end

end # class Inversion::Template::EndTag

