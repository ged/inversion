#!/usr/bin/ruby
# coding: utf-8

# SimpleCov test coverage reporting; enable this using the :coverage rake task
require 'simplecov' if ENV['COVERAGE']

require 'rspec'
require 'loggability'
require 'loggability/spechelpers'

require 'inversion'

Inversion::Template::Tag.load_all


### RSpec helper functions.
module Inversion::SpecHelpers

	###############
	module_function
	###############

	### Make an easily-comparable version vector out of +ver+ and return it.
	def vvec( ver )
		return ver.split('.').collect {|char| char.to_i }.pack('N*')
	end


	### Create a string containing an XML Processing Instruction with the given +name+
	### and +data+.
	def create_pi( name, data )
		return "<?#{name} #{data} ?>"
	end

end


### Mock with RSpec
RSpec.configure do |c|

	c.run_all_when_everything_filtered = true
	c.filter_run :focus
	c.order = 'random'
	c.mock_with( :rspec ) do |mock|
		mock.syntax = :expect
	end

	c.include( Inversion::SpecHelpers )
	c.include( Loggability::SpecHelpers )
end

# vim: set nosta noet ts=4 sw=4:

