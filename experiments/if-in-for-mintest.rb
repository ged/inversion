#!/usr/bin/env ruby

require 'inversion'

template = Inversion::Template.new( <<-END_TEMPLATE )
<?for thing in things ?>
test: <?if thing[:test] ?>Yep.<?end?> 
<?end for ?>
END_TEMPLATE

template.things = []
template.things << {:test => true}
template.things << {:test => false}
template.things << {:test => false}
template.things << {:test => false}
template.things << {:test => true}
template.things << {:test => true}
template.things << {:test => false}

puts template.render
