#!/usr/bin/env ruby

$LOAD_PATH.unshift( "lib" )

require 'benchmark'
require 'inversion'
require 'logger'

# How many times to load each template for the benchmark
ITERATIONS = 25

Inversion.log.level = Logger::FATAL

templatedir = ARGV.shift or abort "usage: #$0 <templatedir>"
templatedir = Pathname( templatedir )
templateglob = templatedir + '**/*.tmpl'

templatefiles = Pathname.glob( templateglob.to_s ).
	collect {|path| path.relative_path_from(templatedir) }
abort "No template files match %s" % [ templateglob ] if templatefiles.empty?

puts '-' * 80
puts "Benchmark: load %d template files from %s" % [ templatefiles.length, templatedir ]
system 'hg', 'id', '-ntiB'
puts '-' * 80

Inversion::Template.configure( :template_paths => [templatedir] )
Benchmark.bmbm do |run|
	templatefiles.sort.each do |path|
		run.report( path.to_s ) { ITERATIONS.times { Inversion::Template.load(path) } }
	end
end
