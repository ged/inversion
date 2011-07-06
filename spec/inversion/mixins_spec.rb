#!/usr/bin/env rspec -cfd -b
# vim: set noet nosta sw=4 ts=4 :

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'spec/lib/helpers'

require 'inversion/mixins'


describe Inversion, "mixins" do

	describe Inversion::Escaping do

		before( :each ) do
			objclass = Class.new do
				include Inversion::Escaping

				def render( state )
					return self.escape( "<something>", state )
				end
			end
			@obj = objclass.new
		end

		it "adds configurable escaping to including classes" do
			render_state = Inversion::RenderState.new( {}, :escape_format => :html )
			@obj.render( render_state ).should == "&lt;something&gt;"
		end

		it "doesn't escape anything if escaping is disabled" do
			render_state = Inversion::RenderState.new( {}, :escape_format => nil )
			@obj.render( render_state ).should == "<something>"
		end

		it "doesn't escape anything if escaping is set to ':none'" do
			render_state = Inversion::RenderState.new( {}, :escape_format => :none )
			@obj.render( render_state ).should == "<something>"
		end
	end
end

