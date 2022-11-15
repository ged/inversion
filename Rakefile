# -*- ruby -*-

require 'rake/deveiate'

Rake::DevEiate.setup( 'inversion' ) do |project|
	project.publish_to = 'deveiate:/usr/local/www/public/code'
	project.default_manifest.include( 'spec/data/**/*.inversion' )
	project.default_manifest.include( 'spec/data/*.tmpl' )
	project.rdoc_generator = :sixfish
end

