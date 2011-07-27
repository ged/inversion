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
require 'inversion/template/timedeltatag'

describe Inversion::Template::TimeDeltaTag do

	before( :all ) do
		@real_tz = ENV['TZ']

        # Make the timezone consistent for testing, using modern zone and
        # falling back to old-style zones if the modern one doesn't seem to
        # work.
		ENV['TZ'] = 'US/Pacific'
        ENV['TZ'] = 'PST8PDT' if Time.now.utc_offset.zero?

		setup_logging( :fatal )
	end

	before( :each ) do
		@past           = "Fri Aug 20 08:21:35.1876455 -0700 2010"
		@pasttime       = Time.parse( @past )
		@pastsecs       = @pasttime.to_i
		@pastdate       = Date.parse( @past )
		@pastdatetime   = DateTime.parse( @past )
		@now            = Time.parse( "Sat Aug 21 08:21:35.1876455 -0700 2010" )
		@future         = "Sun Aug 22 08:21:35.1876455 -0700 2010"
		@futuretime     = Time.parse( @future )
		@futuresecs     = @futuretime.to_i
		@futuredate     = Date.parse( @future )
		@futuredatetime = DateTime.parse( @future )
	end

	after( :all ) do
		reset_logging()
		ENV['TZ'] = @real_tz
	end


	it "renders the attribute as an approximate interval of time if it's a future Time object" do
		Time.stub( :now ).and_return( @now )
		tag = Inversion::Template::TimeDeltaTag.new( "foo" )
		renderstate = Inversion::RenderState.new( :foo => @futuretime )

		tag.render( renderstate ).should == "about a day from now"
	end

	it "renders the attribute as an approximate interval of time if it's a past Time object" do
		Time.stub( :now ).and_return( @now )
		tag = Inversion::Template::TimeDeltaTag.new( "foo" )
		renderstate = Inversion::RenderState.new( :foo => @pasttime )

		tag.render( renderstate ).should == "about a day ago"
	end

	it "renders the attribute as an approximate interval of time if it's a future Date object" do
		Time.stub( :now ).and_return( @now )
		tag = Inversion::Template::TimeDeltaTag.new( "foo" )
		renderstate = Inversion::RenderState.new( :foo => @futuredate )

		tag.render( renderstate ).should == "16 hours from now"
	end

	it "renders the attribute as an approximate interval of time if it's a past Date object" do
		Time.stub( :now ).and_return( @now )
		tag = Inversion::Template::TimeDeltaTag.new( "foo" )
		renderstate = Inversion::RenderState.new( :foo => @pastdate )

		tag.render( renderstate ).should == "2 days ago"
	end

	it "renders the attribute as an approximate interval of time if it's a future DateTime object" do
		Time.stub( :now ).and_return( @now )
		tag = Inversion::Template::TimeDeltaTag.new( "foo" )
		renderstate = Inversion::RenderState.new( :foo => @futuredatetime )

		tag.render( renderstate ).should == "about a day from now"
	end

	it "renders the attribute as an approximate interval of time if it's a past DateTime object" do
		Time.stub( :now ).and_return( @now )
		tag = Inversion::Template::TimeDeltaTag.new( "foo" )
		renderstate = Inversion::RenderState.new( :foo => @pastdatetime )

		tag.render( renderstate ).should == "about a day ago"
	end

	it "renders the attribute as an approximate interval of time if it's a future String object" do
		Time.stub( :now ).and_return( @now )
		tag = Inversion::Template::TimeDeltaTag.new( "foo" )
		renderstate = Inversion::RenderState.new( :foo => @future )

		tag.render( renderstate ).should == "about a day from now"
	end

	it "renders the attribute as an approximate interval of time if it's a past String object" do
		Time.stub( :now ).and_return( @now )
		tag = Inversion::Template::TimeDeltaTag.new( "foo" )
		renderstate = Inversion::RenderState.new( :foo => @past )

		tag.render( renderstate ).should == "about a day ago"
	end

	it "renders the attribute as an approximate interval of time if it's a future epoch Numeric" do
		Time.stub( :now ).and_return( @now )
		tag = Inversion::Template::TimeDeltaTag.new( "foo" )
		renderstate = Inversion::RenderState.new( :foo => @futuresecs )

		tag.render( renderstate ).should == "about a day from now"
	end

	it "renders the attribute as an approximate interval of time if it's a past epoch Numeric" do
		Time.stub( :now ).and_return( @now )
		tag = Inversion::Template::TimeDeltaTag.new( "foo" )
		renderstate = Inversion::RenderState.new( :foo => @pastsecs )

		tag.render( renderstate ).should == "about a day ago"
	end
end
