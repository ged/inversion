#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'pathname'
require 'inversion/mixins'
require 'inversion/template/tag'


# Inversion 'include' tag.
#
# A tag that inserts other template files into the current template.
#
# == Example
#
#   <?include /an/absolute/path/to/a/different/template.tmpl ?>
#   <?include a/relative/path/to/a/different/template.tmpl ?>
#
#
class Inversion::Template::IncludeTag < Inversion::Template::Tag

	### Create a new IncludeTag with the specified +path+.
	def initialize( path, linenum=nil, colnum=nil )
		super
		self.log.debug "Body is: %p" % [ @body ]
		@path = @body
		@included_template = nil
	end


	######
	public
	######

	# The path of the included template
	attr_reader :path


	### Parser callback -- Load the included template and check for recursive includes.
	def before_appending( parsestate )
		@included_template = parsestate.load_subtemplate( self.path )
	end


	### Parser callback -- append the nodes from the included template onto the
	### tree of the including template.
	def after_appending( parsestate )
		parsestate.append_tree( @included_template.node_tree )
	end

end # class Inversion::Template::IncludeTag

