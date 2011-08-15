#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/tag'

# Inversion subscription tag.
#
# The subscribe tag places one or more published nodes from subtemplates.
#
# == Syntax
#
#   <!-- Outer template -->
#   <html>
#     <head>
#       <title><?subscribe title || Untitled ?></title>
#       <?subscribe headers ?>
#     </head>
#     <body><?attr body ?></body>
#   </html>
#
#   <!-- In the body template, add a stylesheet link to the outer
#        template's <head> -->
#   <?publish headers ?>
#      <link rel="stylesheet" ... />
#   <?end ?>
#   <div>(page content)</div>
#
class Inversion::Template::SubscribeTag < Inversion::Template::Tag

	### Create a new SubscribeTag with the given +body+.
	def initialize( body, line=nil, column=nil )
		super

		unless self.body =~ /^([a-z]\w+)(?:\s*\|\|\s*(.+))?$/
			raise Inversion::ParseError,
				"malformed subscribe: %p" % [ self.body ]
		end

		key, default = $1, $2

		@key = key.to_sym
		@content = []
		@default = default
	end


	######
	public
	######

	# The name of the key the nodes will be published under
	attr_reader :key


	### Tell the +renderstate+ that this tag is interested in nodes that are published with
	### its key.
	def before_rendering( renderstate )
		renderstate.subscribe( self.key, self )
	end


	### Return the subscribe node itself to act as a placeholder for subscribed nodes.
	def render( renderstate )
		return self
	end


	### Pub/sub callback. Called from the RenderState when a PublishTag publishes +nodes+
	### with the same key as the current tag.
	def publish( *nodes )
		@content.push( *nodes )
	end


	### Stringify and join all of the published nodes for this subscription and return them
	### as a String.
	def to_s
		if @content.empty?
			self.log.debug "Nothing published with the %p key, defaulting to %p" %
				[ self.key, @default ]
			return @default.to_s
		else
			return @content.map( &:to_s ).join( '' )
		end
	end

end # class Inversion::Template::SubscribeTag

