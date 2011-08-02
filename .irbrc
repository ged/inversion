#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:

BEGIN {
    require 'pathname'
	$LOAD_PATH.unshift( Pathname.new( __FILE__ ).dirname + 'lib' )
}

begin
	require 'inversion'
rescue Exception => err
	$stderr.puts "Inversion failed to load: %p: %s" % [ err.class, err.message ]
end

