#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

require_relative '../helpers'

begin
	require 'sinatra'
	require 'rack/test'
	require 'inversion/sinatra'
	$sinatra_support = true
rescue LoadError => err
	warn "Sintra support testing disabled: %p: %s" % [ err.class, err.message ]
	$sinatra_support = false
end

describe "Sinatra support", :if => $sinatra_support do
	include Rack::Test::Methods if defined?( ::Rack )

	before( :each ) do
		@datadir = Pathname( __FILE__ ).dirname.parent + 'data'
	end

	def app
		Sinatra::Base.set :environment, :test
		@app
	end

	it "extends the Sinatra DSL with an #inversion helper method" do
		expect( Sinatra::Base.instance_methods ).to include( :inversion )
	end

	it "renders .inversion files in views path" do
		@app = Sinatra.new( Sinatra::Base ) do
			set :views, File.dirname( __FILE__ ) + '/../data/sinatra'
			get '/' do
				inversion :hello
			end
		end

		get '/'
		expect( last_response ).to be_ok
		expect( last_response.body ).to eq( 'Hello, Sinatra!' )
	end

end

