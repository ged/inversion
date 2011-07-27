#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template'

# A mixin for a tag that manages conditional rendering of its subnodes.
module Inversion::Template::ConditionalTag

	### Add conditional instance variables.
	def initialize( *args ) # :notnew:
		super

		@rendering_enabled     = false
		@rendering_was_enabled = false
	end


	#########
	protected
	#########

	### Enable rendering of subnodes.
	def enable_rendering
		self.log.debug "  enabling rendering."
		@rendering_enabled = @rendering_was_enabled = true
	end


	### Disable rendering of subnodes.
	def disable_rendering
		self.log.debug "  disabling rendering."
		@rendering_enabled = false
	end


	### Return +true+ if rendering is enabled.
	def rendering_enabled?
		return @rendering_enabled
	end


	### Return +true+ if rendering has been enabled since the tag started rendering.
	def rendering_was_enabled?
		return @rendering_was_enabled
	end


end # module Inversion::Template::ConditionalTag

