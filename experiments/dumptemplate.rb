#!/usr/bin/env ruby

BEGIN {
	require 'pathname'

	basedir = Pathname( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( libdir.to_s )
}

require 'pp'
require 'logger'
require 'inversion'

file = ARGV.shift or abort "No template file specified."
io = File.open( file, 'r' )

Inversion.log.level = Logger::DEBUG
tmpl = Inversion::Template.load( file )



