#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion' unless defined?( Inversion )
require 'inversion/template' unless defined?( Inversion::Template )
require 'inversion/template/tag' unless defined?( Inversion::Template::Tag )

# Closing tag class
class Inversion::Template::EndTag < Inversion::Template::Tag
	include Inversion::Loggable


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


	### Remember what the current node of the +state+ is for the comment body later.
	def before_append( state )
		@opener = state.current_node
		super
	end


	### Render the tag as the body of a comment, suitable for template debugging.
	### @return [String]  the tag as the body of a comment
	def as_comment_body
		return "End of %s" % [ self.opener.as_comment_body ]
	end

end # class Inversion::Template::EndTag

