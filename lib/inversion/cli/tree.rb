# -*- ruby -*-

require 'inversion'
require 'inversion/cli'


# Tree command
module Inversion::CLI::TreeCommand
	extend Inversion::CLI::Subcommand


	desc "Dump the node tree of a template."
	long_desc %{
		Load, parse, and dump the resulting node tree of a given
		Inversion template. This is mostly useful for debugging custom
		tags, but can also make it easier to diagnose strange template
		behavior.
	}
	arg :TEMPLATE_PATH
	command :tree do |tree|

		tree.action do |globals, options, args|
			path = args.first or exit_now!( "No template specified!" )

			template = self.load_template( path ) or exit_now!('Template failed to load.')

			self.output_blank_line
			self.output_template_header( template )
			self.output_template_nodes( template.node_tree )
		end

	end


	###############
	module_function
	###############

	### Output the given `tree` of nodes at the specified `indent` level.
	def output_template_nodes( tree, indent=0 )
		indenttxt = ' ' * indent
		tree.each do |node|
			self.prompt.say( indenttxt + node.as_comment_body )
			self.output_template_nodes( node.subnodes, indent+4 ) if node.is_container?
		end
	end


	### Dump the node tree of the given `templates`.
	def dump_node_trees( templates )
		templates.each do |path|
			template = self.load_template( path )
			self.output_blank_line
			self.output_template_header( template )
			self.output_template_nodes( template.node_tree )
		end
	end


	### Output the given `tree` of nodes at the specified `indent` level.
	def output_template_nodes( tree, indent=0 )
		indenttxt = ' ' * indent
		tree.each do |node|
			self.prompt.say( indenttxt + node.as_comment_body )
			self.output_template_nodes( node.subnodes, indent+4 ) if node.is_container?
		end
	end

end # module Inversion::CLI::TreeCommand

