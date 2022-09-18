# -*- ruby -*-

require 'inversion'
require 'inversion/cli'


# Api command
module Inversion::CLI::ApiCommand
	extend Inversion::CLI::Subcommand


	desc "Dump the Ruby API of the given TEMPLATEs"
	long_desc %{
		Load the given TEMPLATE and dump the out the Ruby API of the resulting object.
	}
	arg :TEMPLATE, :multiple
	command :api do |api|

		api.action do |globals, options, args|
			args.each do |path|

				template = self.load_template( path ) or exit_now!('Template failed to load.')

				self.output_blank_line
				self.output_template_header( template )
				self.describe_template_api( template )
				self.describe_publications( template )
				self.describe_subscriptions( template )
			end
		end

	end


	###############
	module_function
	###############


	### Output a description of the +template+'s attributes, subscriptions, etc.
	def describe_template_api( template )
		attrs = template.attributes.keys.map( &:to_s )
		return if attrs.empty?

		self.output_subheader "%d Attribute/s" % [ attrs.length ]
		self.display_list( attrs )
		self.output_blank_line
	end


	### Output a list of sections the template publishes.
	def describe_publications( template )
		ptags = template.node_tree.find_all {|node| node.is_a?(Inversion::Template::PublishTag) }
		return if ptags.empty?

		pubnames = ptags.map( &:key ).map( &:to_s ).uniq.sort
		self.output_subheader "%d Publication/s" % [ pubnames.length ]
		self.display_list( pubnames )
		self.output_blank_line
	end


	### Output a list of sections the template subscribes to.
	def describe_subscriptions( template )
		stags = template.node_tree.find_all {|node| node.is_a?(Inversion::Template::SubscribeTag) }
		return if stags.empty?

		subnames = stags.map( &:key ).map( &:to_s ).uniq.sort
		self.output_subheader "%d Subscription/s" % [ subnames.length ]
		self.display_list( subnames )
		self.output_blank_line
	end

end # module Inversion::CLI::ApiCommand

