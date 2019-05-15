# -*- ruby -*-
# frozen_string_literal: true
# vim: set noet nosta sw=4 ts=4 :

require 'nokogiri'
require 'ripper'
require 'pp'
require 'chunker'

include Chunker

class InversionTemplate

	def initialize( io )
		@document = Nokogiri::HTML( io )
		@attrs = {}

		self.parse()
	end

	def parse
		@document.xpath( '//processing-instruction()' ).each do |pi|
			self.parse_processing_instruction( pi )
		end
	end

	def parse_processing_instruction( pi )
		puts "text is: %p" % [ pi.text ]

		identifier = pi.text.strip[ /[a-z]\w+/ ]
		puts "defining a method for #{identifier} "

		@attrs[ identifier.to_sym ] = []
		block = self.create_tag( pi.name, pi.text )
		self.class.send( :define_method, identifier, &block )
		self.class.send( :define_method, "#{identifier}=" ) do |arg|
			@attrs[ identifier ] << arg
		end
	end


	def create_tag( type, content )
		case type

		when 'call'
			return eval "lambda { #{content} }", binding()
		else
			raise "D'oh!"
		end
	end

	def render
		@document.each do |elem|
			# if elem.is_a?( Nokogiri::XML::ProcessingInstruction )
			puts elem
		end
	end
	alias_method :to_s, :render

end

template1 = InversionTemplate.new( DATA_TEMPLATE1 )
template1.foo = "woo!"

pp template1.to_s

__END__
__TEMPLATE1__

<div>
	<p>something awesome</p>
	<?call foo.length >
	<?call person.names.select {|name| name != supervisor.lastname } ?>	
</div>

