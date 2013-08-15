#!/usr/bin/env ruby

require 'erb'

TEMPLATE = <<END_TEMPLATE
<% var = "foo" %>
END_TEMPLATE

var = 1
template = ERB.new( TEMPLATE )

puts "Before rendering, var = %p" % [ var ]
output = template.result( binding() )
puts "After rendering, var = %p" % [ var ]

# Before rendering, var = 1
# After rendering, var = "foo"

