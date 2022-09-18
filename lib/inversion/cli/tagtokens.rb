# -*- ruby -*-

require 'inversion'
require 'inversion/cli'


# Tagtokens command
module Inversion::CLI::TagTokensCommand
	extend Inversion::CLI::Subcommand


	desc "Dump a token phrase for the given STATEMENT"
	long_desc %{
		Parse the given STATEMENT as Ruby and dump the resulting lexical
		tokens. This is useful when creating new tags.
	}
	arg :STATEMENT
	command :tagtokens do |tagtokens|

		tagtokens.action do |globals, options, args|
			statement = args.join(' ')

			require 'ripper'
			tokens = Ripper.lex( statement ).collect do |(pos, tok, text)|
				"%s<%p>" % [ tok.to_s.sub(/^on_/,''), text ]
			end.join(' ')

			self.prompt.say( tokens )
		end

	end

end # module Inversion::CLI::TagTokensCommand

