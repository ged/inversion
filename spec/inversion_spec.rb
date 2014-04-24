#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative 'helpers'

require 'inversion'

describe Inversion do

	it "defines a version" do
		expect( described_class::VERSION ).to match( /^\d+(\.\d+)*$/ )
	end


	describe "version methods" do

		it "returns a version string if asked" do
			expect( described_class.version_string ).to match( /\w+ [\d.]+/ )
		end

		it "returns a version string with a build number if asked" do
			expect(
				described_class.version_string(true)
			).to match( /\w+ [\d.]+ \(build [[:xdigit:]]+\)/ )
		end
	end

end

