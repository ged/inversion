#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'yaml'
require 'inversion/mixins'
require 'inversion/template/tag'


# Inversion 'config' tag.
#
# A tag that dynamically alters the behavior of the template.
#
# == Examples
#
#   <?config comment_start: /* ?>
#   <?config comment_end: */ ?>
#
#   <?config
#       on_render_error: propagate
#       debugging_comments: true
#       comment_start: /*
#       comment_end: */
#   ?>
#
#   <?config { comment_start: "/*", comment_end: "*/" } ?>
#
#
class Inversion::Template::ConfigTag < Inversion::Template::Tag
	include Inversion::HashUtilities


	### Create a new ConfigTag with the specified +body+.
	def initialize( body, linenum=nil, colnum=nil )
		raise Inversion::ParseError, 'Empty config settings' if
			body.nil? || body.strip.empty?

		opts = YAML.load( body )
		@options = symbolify_keys( opts )

		super
	end


	######
	public
	######

	# The config options that will be modified
	attr_reader :options


	### Override the options in the +parsestate+ when the config is appended to
	### the tree.
	def before_appending( parsestate )
		parsestate.options.merge!( self.options )
	end


	### Override the options in the +renderstate+ when the config is rendered.
	def before_rendering( renderstate )
		renderstate.options.merge!( self.options )
	end

end # class Inversion::Template::ConfigTag

