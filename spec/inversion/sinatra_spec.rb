#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent.parent
	libdir  = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s )  unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'spec/lib/helpers'

begin
	require 'rack/test'
	require 'inversion/sinatra'
	$sinatra_support = true
rescue LoadError => err
	warn "Sintra support testing disabled: %p: %s" % [ err.class, err.message ]
	$sinatra_support = false
end

describe "Sinatra support", :if => $sinatra_support do
	include Rack::Test::Methods if defined?( ::Rack )

	before( :all ) do
		setup_logging( :fatal )
	end

	before( :each ) do
		@datadir = Pathname( __FILE__ ).dirname.parent + 'data'
		Sinatra::Base.set :environment, :test
	end

	def app
		@app
	end

	it "extends the Sinatra DSL with an #inversion helper method" do
		Sinatra::Base.instance_methods.should include( :inversion )
	end

	it "renders .inversion files in views path" do
		@app = Sinatra.new( Sinatra::Base ) do
			set :views, File.dirname( __FILE__ ) + '/../data/sinatra'
			get '/' do
				inversion :hello
			end
		end

		get '/'
		last_response.should be_ok
	    last_response.body.should == 'Hello, Sinatra!'
	end

end

