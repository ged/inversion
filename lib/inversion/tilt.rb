#!/usr/bin/env ruby

require 'tilt'

# Only add support if Tilt's already been loaded.
if defined?( ::Tilt )

	# An adapter class for Tilt (https://github.com/rtomayko/tilt)
	# :TODO: Add an example or two.
	class Inversion::TiltWrapper < Tilt::Template

		### Tilt::Template API: returns true if Inversion is loaded.
		def self::engine_initialized?
			return defined?( Inversion::Template )
		end


		### Tilt::Template API: lazy-load Inversion
		def initialize_engine
			require_template_library 'inversion'
		end


		### Tilt::Template API: load a template
		def prepare
			# Load the instance and set the path to the source
			@template = Inversion::Template.new( self.data, self.options )
			@template.source_file = self.file
		end


		### Hook the template's render phase.
		def render( *args )
			self.evaluate( *args )
		end

		### Tilt::Template API: render the template with the given +scope+, +locals+, and +block+.
		def evaluate( scope, locals, &block )
			@template.attributes.merge!( scope.to_h ) if scope.respond_to?( :to_h )
			@template.attributes.merge!( locals )

			return @template.render( &block )
		end

	end # class Inversion::TiltWrapper

	# Also add #each to Inversion::Template so they can be returned from actions directly, too.
	module Inversion::TemplateTiltAdditions

		# TODO: Factor the common parts of this out in Inversion::Template so there's no
		# duplication.
		def each
			self.log.info "rendering template 0x%08x (Sinatra-style)" % [ self.object_id/2 ]
			state = Inversion::RenderState.new( nil, self.attributes, self.options )

			# Pre-render hook
			self.walk_tree {|node| node.before_rendering(state) }

			self.log.debug "  rendering node tree: %p" % [ @node_tree ]
			self.walk_tree {|node| state << node }

			# Post-render hook
			self.walk_tree {|node| node.after_rendering(state) }

			self.log.info "  done rendering template 0x%08x" % [ self.object_id/2 ]
			return state.destination.each do |node|
				yield( node.to_s )
			end
		end

	end # module Inversion::TemplateTiltAdditions

	# Add the mixin to Template
	class Inversion::Template
		include Inversion::TemplateTiltAdditions
	end


	Tilt.register( Inversion::TiltWrapper, 'tmpl', 'inversion' )

end

