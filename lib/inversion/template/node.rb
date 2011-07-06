#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/mixins'
require 'inversion/template' unless defined?( Inversion::Template )

# Inversion template node base class
class Inversion::Template::Node
	include Inversion::AbstractClass


	### Create a new TextNode with the specified +source+.
	### @param [String] source   the text source to wrap in the node object
	### @param [Integer] linenum the line number the tag was parsed from
	### @param [Integer] colnum  the column number the tag was parsed from
	def initialize( body, linenum=nil, colnum=nil )
		@body    = body
		@linenum = linenum
		@colnum  = colnum
	end


	######
	public
	######

	# The line number the node was parsed from in the template source (if known)
	attr_reader :linenum

	# The column number the node was parsed from in the template source (if known)
	attr_reader :colnum


	### Render the node using the given +render_state+. By default, rendering a node
	### returns +nil+.
	def render( render_state=nil )
		return nil
	end


	### Render the node as a comment
	def as_comment_body
		return self.inspect
	end


	### Returns +true+ if the node introduces a new parsing/rendering scope.
	def is_container?
		return false
	end
	alias_method :container?, :is_container?


	### Return the location of the tag in the template, if it was parsed from one (i.e.,
	### if it was created with a StringScanner)
	def location
		return "line %s, column %s" % [
			self.linenum || '??',
			self.colnum  || '??',
		]
	end


	### Default (no-op) implementation of the before_appending callback. This exists so defining
	### the append callbacks are optional for Node's subclasses.
	def before_appending( state )
		# Nothing to do
		return nil
	end
	alias_method :before_append, :before_appending


	### Default (no-op) implementation of the after_appending callback. This exists so defining
	### the append callbacks are optional for Node's subclasses.
	def after_appending( state )
		# Nothing to do
		return nil
	end
	alias_method :after_append, :after_appending


	### Default (no-op) implementation of the before_rendering callback. This exists so defining
	### the rendering callbacks are optional for Node's subclasses.
	def before_rendering( state=nil )
		# Nothing to do
		return nil
	end
	alias_method :before_render, :before_rendering


	### Default (no-op) implementation of the after_rendering callback. This exists so defining
	### the rendering callbacks are optional for Node's subclasses.
	def after_rendering( state=nil )
		# Nothing to do
		return nil
	end
	alias_method :after_render, :after_rendering

end # class Inversion::Template::Node

