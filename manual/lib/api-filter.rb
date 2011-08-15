#!/usr/bin/ruby 
#
# A manual filter to generate links from the Darkfish API.
#
# Authors:
# * Michael Granger <ged@FaerieMUD.org>
# * Mahlon E. Smith <mahlon@martini.nu>
#


### A filter for generating links from the generated API documentation. This allows you to refer
### to class documentation by simply referencing a class name.
###
### Links are XML processing instructions. Pages can be referenced as such:
###
###   <?api Class::Name ?>
###   <?api "click here":Class::Name ?>
###
class Hoe::ManualGen::APIFilter < Hoe::ManualGen::PageFilter

	# PI	   ::= '<?' PITarget (S (Char* - (Char* '?>' Char*)))? '?>'
	ApiPI = %r{
		<\?
			api			# Instruction Target
			\s+
			(?:"					
				(.*?)   # Optional link text [$1]
			":)?
			(.*?)	    # Class name [$2]
			([\.#].*?)? # Method anchor [$3]
			\s+
		\?>
	  }x


	######
	public
	######

	### Process the given +source+ for <?api ... ?> processing-instructions, calling out
	def process( source, page, metadata )

		apipath = metadata.api_dir or
			raise "The API output directory is not defined in the manual task."

		return source.gsub( ApiPI ) do |match|
			# Grab the tag values
			link_text = $1
			classname = $2
			anchor    = $3

			self.generate_link( page, apipath, classname, anchor, link_text )
		end
	end


	### Create an HTML link fragment from the parsed ApiPI.
	def generate_link( current_page, apipath, classname, anchor, link_text=nil )

		classpath = "%s.html" % [ classname.gsub('::', '/') ]
		classfile = apipath + classpath
		classuri  = current_page.basepath + 'api' + classpath

		if classfile.exist?
			return %{<a href="%s%s">%s</a>} % [
				classuri,
				add_anchor( anchor ),
				link_text || classname
			]
		else
			link_text ||= classname
			error_message = "Could not find a link for class '%s'" % [ classname ]
			$stderr.puts( error_message )
			return %{<a href="#" title="#{error_message}" class="broken-link">#{link_text}</a>}
		end
	end


	### Attach a method anchor.
	def add_anchor( anchor )
		return '' unless anchor

		method_type = anchor.slice!( 0, 1 )
		return "#method-%s-%s" % [
			( method_type == '#' ? 'i' : 'c' ),
			anchor
		]
	end
end

