#!/usr/bin/env ruby

ary = [
	:one,
	:two,
	[ :three_one, :three_two ],
	:three
]

enum = Enumerator.new do |y|
	stack = [ ary ]
	walker = lambda {|obj|
		stack
	}

	ary.each do |obj|
		if obj.is_a?( Array )
		else
			y.yield( obj )
		end
	end
end

