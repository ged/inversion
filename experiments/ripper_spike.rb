#!/usr/bin/env ruby

require 'pp'
require 'ripper'
require 'nokogiri'

class IdentifierFinder < Ripper::Filter

	def initialize( *args )
		@after_period = false
		super
	end

	def on_ident( tok, data )
		data << tok unless @after_period
		@after_period = false
		data
	end

	def on_period( tok, data )
		@after_period = true
		data
	end

	def on_default( event, tok, data )
		$stderr.puts "%s: %p" % [ event, tok ]
		@after_period = false
		data
	end

end



$stdout.sync = true

doc = Nokogiri::XML( DATA.read )
doc.xpath( '//processing-instruction()' ).each do |elem|
	# identifiers = IdentifierFinder.new( elem.text ).parse( [] )
	# $stderr.puts "%s: %p" % [ elem, tree ]

	iter = Ripper.sexp( elem.text ).flatten.each_cons( 3 )
	pp iter.find_all {|op, _, ident| op == :var_ref }.map {|triple| triple[2] } 
end



__END__

<div>

	<?call user.firstname ?>
	<?call user.lastname ?>
	<?call user.gecos || config.no_gecos_message ?>
	<?call 10.times {|i| user.id } ?>

</div>


