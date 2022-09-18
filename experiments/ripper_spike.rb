# -*- ruby -*-
# vim: set noet nosta sw=4 ts=4 :

require 'pp'
require 'ripper'

class IdentifierFinder < Ripper::Filter

	### Add the identifier to the accumulator
	def on_ident( tok, data )
		data << tok
	end

	def on_default( event, tok, data )
		$stderr.puts "%s: %p" % [ event, tok ]
		data
	end


end

$stderr.puts "Creating an IdentifierFinder"
idfinder = IdentifierFinder.new( "foo" )
$stderr.puts "  %p" % [ idfinder ]
identifiers = idfinder.parse( [] )
$stderr.puts "  done: %p" % [ identifiers ]



# $stdout.sync = true
#
# doc = Nokogiri::XML( DATA.read )
# doc.xpath( '//processing-instruction()' ).each do |elem|
# 	# identifiers = IdentifierFinder.new( elem.text ).parse( [] )
# 	# $stderr.puts "%s: %p" % [ elem, tree ]
#
# 	iter = Ripper.sexp( elem.text ).flatten.each_cons( 3 )
# 	pp iter.find_all {|op, _, ident| op == :var_ref }.map {|triple| triple[2] }
# end



__END__

<div>

	<?call user.firstname ?>
	<?call user.lastname ?>
	<?call user.gecos || config.no_gecos_message ?>
	<?call 10.times {|i| user.id } ?>

</div>


