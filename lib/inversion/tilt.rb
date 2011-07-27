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


		### Tilt::Template API: render the template with the given +scope+, +locals+, and +block+.
		def evaluate( scope, locals, &block )
			@template.attributes.merge!( scope.to_h ) if scope.respond_to?( :to_h )
			@template.attributes.merge!( locals )

			return @template.render
		end

	end # class Inversion::TiltWrapper

	Tilt.register( Inversion::TiltWrapper, 'tmpl', 'inversion' )

end

