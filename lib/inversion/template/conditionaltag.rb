#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template'

# A mixin for a tag that allows it to contain other nodes.
#
# @author Michael Granger <ged@FaerieMUD.org>
# @author Mahlon E. Smith <mahlon@martini.nu>
#
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
		@rendering_enabled = @rendering_was_enabled = true
	end


	### Disable rendering of subnodes.
	def disable_rendering
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


	### Render the tag's subnodes according to the tag's logical state
	def render_subnodes( state )
		result = []

		# walk the subtree, modifying the logic flags for else and elsif tags,
		# and rendering nodes if rendering is enabled
		self.subnodes.each do |node|
			case node
			when Inversion::Template::ElsifTag
				if !self.rendering_was_enabled? && node.render( state )
					self.enable_rendering
				else
					self.disable_rendering
				end

			when Inversion::Template::ElseTag
				if !self.rendering_was_enabled?
					self.enable_rendering
				else
					self.disable_rendering
				end

			else
				result << node.render( state ) if self.rendering_enabled?
			end
		end

		return result.join
	end

end # module Inversion::Template::ConditionalTag

require 'inversion/template/elsiftag'
require 'inversion/template/elsetag'
