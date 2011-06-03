#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion' unless defined?( Inversion )
require 'inversion/template' unless defined?( Inversion::Template )
require 'inversion/template/tag' unless defined?( Inversion::Template::Tag )

# Closing tag class
class Inversion::Template::EndTag < Inversion::Template::Tag
	include Inversion::Loggable


	### Render the tag as the body of a comment, suitable for template debugging.
	### @return [String]  the tag as the body of a comment
	def as_comment_body
		if self.body
			return "End: %s" % [ tagname, self.body.dump ]
		else
			return nil
		end
	end

end # class Inversion::Template::EndTag

