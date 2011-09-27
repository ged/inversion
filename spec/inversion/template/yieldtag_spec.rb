#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent.parent.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'spec/lib/helpers'
require 'inversion/template/yieldtag'

describe Inversion::Template::YieldTag do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	it "calls the renderstate's block before rendering, and renders as its return value" do
		tag = Inversion::Template::YieldTag.new( '' )
		renderstate = Inversion::RenderState.new do |state|
			:return_value
		end
		tag.before_rendering( renderstate )

		rendered_output = renderstate.with_destination( [] ) do
			renderstate << tag
		end

		rendered_output.should == [ :return_value ]
	end

	it "renders as nothing if there wasn't a render block" do
		tag = Inversion::Template::YieldTag.new( '' )
		renderstate = Inversion::RenderState.new
		tag.before_rendering( renderstate )

		rendered_output = renderstate.with_destination( [] ) do
			renderstate << tag
		end

		rendered_output.should == [ nil ]
	end

end
