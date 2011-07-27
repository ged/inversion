#!/usr/bin/env ruby

begin
	require 'inversion/tilt'
	require 'sinatra'
	require 'sinatra/base'
rescue LoadError => err
	warn "Couldn't load Inversion Sinatra support: %s: %s" % [ err.class.name, err.message ]
end

# Add support for Tilt (https://github.com/rtomayko/tilt) if it's already been loaded.
if defined?( ::Sinatra ) # :nodoc:

	# A mixin to add Inversion support to Sinatra::Base
	module Inversion::SinatraTemplateHelpers

		### Add an 'inversion' helper method to Sinatra's template DSL:
		###
		###   get '/' do
		###     inversion :company_directory, :locals => { :people => People.all }
		###   end
		def inversion( template, options={}, locals={} )
			render :inversion, template, options, locals
		end

	end # Inversion::SinatraTemplateHelpers

	# Inject Inversion helpers as a mixin
	# :stopdoc:
	class Sinatra::Base
		include Inversion::SinatraTemplateHelpers
	end

end

