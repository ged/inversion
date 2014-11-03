#!/usr/bin/ruby -*- ruby -*-

require 'pathname'

$LOAD_PATH.unshift( 'lib' )

begin
	require 'inversion'

rescue Exception => e
	$stderr.puts "Ack! Inversion libraries failed to load: #{e.message}\n\t" +
		e.backtrace.join( "\n\t" )
end

