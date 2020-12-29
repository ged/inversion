#!/usr/bin/ruby
# coding: utf-8

# SimpleCov test coverage reporting; enable this using the :coverage rake task
require 'simplecov' if ENV['COVERAGE']

require 'rspec'
require 'rspec/wait'
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
RSpec.configure do |config|

	config.mock_with( :rspec ) do |mock|
		mock.syntax = :expect
	end

	config.disable_monkey_patching!
	config.example_status_persistence_file_path = "spec/.status"
	config.filter_run :focus
	config.filter_run_when_matching :focus
	config.order = :random
	config.profile_examples = 5
	config.run_all_when_everything_filtered = true
	config.shared_context_metadata_behavior = :apply_to_host_groups
	config.wait_timeout = 3
	# config.warnings = true

	config.include( Inversion::SpecHelpers )
	config.include( Loggability::SpecHelpers )
end

# vim: set nosta noet ts=4 sw=4:

