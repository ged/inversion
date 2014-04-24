#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../../helpers'

require 'inversion/template/yieldtag'

describe Inversion::Template::YieldTag do


	it "calls the renderstate's block before rendering, and renders as its return value" do
		tag = Inversion::Template::YieldTag.new( '' )
		renderstate = Inversion::RenderState.new do |state|
			:return_value
		end
		tag.before_rendering( renderstate )

		rendered_output = renderstate.with_destination( [] ) do
			renderstate << tag
		end

		expect( rendered_output ).to eq([ :return_value ])
	end

	it "renders as nothing if there wasn't a render block" do
		tag = Inversion::Template::YieldTag.new( '' )
		renderstate = Inversion::RenderState.new
		tag.before_rendering( renderstate )

		rendered_output = renderstate.with_destination( [] ) do
			renderstate << tag
		end

		expect( rendered_output ).to eq([ nil ])
	end

end
