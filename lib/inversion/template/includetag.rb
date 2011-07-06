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
	include Inversion::Loggable


	### Create a new IncludeTag with the specified +path+.
	### @param [String]  path  the path to the include template
	### @param [Integer] linenum the line number the tag was parsed from
	### @param [Integer] colnum  the column number the tag was parsed from
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


	### Add nodes from the template @path into the current +parsestate+.
	### @param [Inversion::Template::Parser::State] parsestate  the parse state
	def after_appending( parsestate )
		parsestate.append_tree( @included_template.node_tree )
	end

end # class Inversion::Template::IncludeTag

