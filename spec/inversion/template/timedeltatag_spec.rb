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

	MINUTES = 60
	HOURS   = 60  * MINUTES
	DAYS    = 24  * HOURS
	WEEKS   = 7   * DAYS
	MONTHS  = 30  * DAYS
	YEARS   = 365.25 * DAYS

	before( :all ) do
		@real_tz = ENV['TZ']

        # Make the timezone consistent for testing, using modern zone and
        # falling back to old-style zones if the modern one doesn't seem to
        # work.
		ENV['TZ'] = 'US/Pacific'
        ENV['TZ'] = 'PST8PDT' if Time.now.utc_offset.zero?

		setup_logging( :fatal )

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

	before( :each ) do
		@tag = Inversion::Template::TimeDeltaTag.new( "foo" )
		Time.stub( :now ).and_return( @now )
	end

	after( :all ) do
		reset_logging()
		ENV['TZ'] = @real_tz
	end


	it "renders the attribute as an approximate interval of time if it's a future Time object" do
		renderstate = Inversion::RenderState.new( :foo => @futuretime )
		@tag.render( renderstate ).should == "about a day from now"
	end

	it "renders the attribute as an approximate interval of time if it's a past Time object" do
		renderstate = Inversion::RenderState.new( :foo => @pasttime )
		@tag.render( renderstate ).should == "about a day ago"
	end

	it "renders the attribute as an approximate interval of time if it's a future Date object" do
		renderstate = Inversion::RenderState.new( :foo => @futuredate )
		@tag.render( renderstate ).should == "16 hours from now"
	end

	it "renders the attribute as an approximate interval of time if it's a past Date object" do
		renderstate = Inversion::RenderState.new( :foo => @pastdate )
		@tag.render( renderstate ).should == "2 days ago"
	end

	it "renders the attribute as an approximate interval of time if it's a future DateTime object" do
		renderstate = Inversion::RenderState.new( :foo => @futuredatetime )
		@tag.render( renderstate ).should == "about a day from now"
	end

	it "renders the attribute as an approximate interval of time if it's a past DateTime object" do
		renderstate = Inversion::RenderState.new( :foo => @pastdatetime )
		@tag.render( renderstate ).should == "about a day ago"
	end

	it "renders the attribute as an approximate interval of time if it's a future String object" do
		renderstate = Inversion::RenderState.new( :foo => @future )
		@tag.render( renderstate ).should == "about a day from now"
	end

	it "renders the attribute as an approximate interval of time if it's a past String object" do
		renderstate = Inversion::RenderState.new( :foo => @past )
		@tag.render( renderstate ).should == "about a day ago"
	end

	it "renders the attribute as an approximate interval of time if it's a future epoch Numeric" do
		renderstate = Inversion::RenderState.new( :foo => @futuresecs )
		@tag.render( renderstate ).should == "about a day from now"
	end

	it "renders the attribute as an approximate interval of time if it's a past epoch Numeric" do
		renderstate = Inversion::RenderState.new( :foo => @pastsecs )
		@tag.render( renderstate ).should == "about a day ago"
	end


	describe "time period calculation" do

		before( :all ) do
			@now_epoch = @now.to_i
		end

		it "renders a period of a minute or less as 'less than a minute'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 44 )
			@tag.render( renderstate ).should == "less than a minute from now"
		end

		it "renders a period of 58 seconds as 'a minute'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 58 )
			@tag.render( renderstate ).should == "a minute from now"
		end

		it "renders a period of 60 seconds as 'a minute'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 60 )
			@tag.render( renderstate ).should == "a minute from now"
		end

		it "renders a period of 68 seconds as 'a minute'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 68 )
			@tag.render( renderstate ).should == "a minute from now"
		end

		it "renders a period of 93 seconds as '2 minutes'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 93 )
			@tag.render( renderstate ).should == "2 minutes from now"
		end

		it "renders a period of 30 minutes as '30 minutes'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 30 * MINUTES )
			@tag.render( renderstate ).should == "30 minutes from now"
		end

		it "renders a period of 58 minutes as 'about an hour'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 58 * MINUTES )
			@tag.render( renderstate ).should == "about an hour from now"
		end

		it "renders a period of 89 minutes as 'about an hour'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 89 * MINUTES )
			@tag.render( renderstate ).should == "about an hour from now"
		end

		it "renders a period of 95 minutes as '2 hours'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 95 * MINUTES )
			@tag.render( renderstate ).should == "2 hours from now"
		end

		it "renders a period of 17 hours as '17 hours'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 17 * HOURS )
			@tag.render( renderstate ).should == "17 hours from now"
		end

		it "renders a period of 20 hours as 'about a day'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 20 * HOURS )
			@tag.render( renderstate ).should == "about a day from now"
		end

		it "renders a period of 6 days as '6 days'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 6 * DAYS )
			@tag.render( renderstate ).should == "6 days from now"
		end

		it "renders a period of 11 days as 'about a week'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 11 * DAYS )
			@tag.render( renderstate ).should == "about a week from now"
		end

		it "renders a period of 18 days as '3 weeks'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 18 * DAYS )
			@tag.render( renderstate ).should == "3 weeks from now"
		end

		it "renders a period of 10 weeks as '10 weeks'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 10 * WEEKS )
			@tag.render( renderstate ).should == "10 weeks from now"
		end

		it "renders a period of 4 months as '4 months'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 4 * MONTHS )
			@tag.render( renderstate ).should == "4 months from now"
		end

		it "renders a period of 14 months as '14 months'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 14 * MONTHS )
			@tag.render( renderstate ).should == "14 months from now"
		end

		it "renders a period of 20 months as '2 years'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 20 * MONTHS )
			@tag.render( renderstate ).should == "2 years from now"
		end

		it "renders a period of 120 years as '120 years'" do
			renderstate = Inversion::RenderState.new( :foo => @now_epoch + 120 * YEARS )
			@tag.render( renderstate ).should == "120 years from now"
		end

	end

end
