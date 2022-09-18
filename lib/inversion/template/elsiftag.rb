# -*- ruby -*-
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template' unless defined?( Inversion::Template )
require 'inversion/template/attrtag'
require 'inversion/template/commenttag'
require 'inversion/template/iftag'


# Inversion 'elsif' tag.
#
# This tag adds a conditional logical switch to an IfTag. If the IfTag's condition was false,
# but the attribute or methodchain of the elsif is true, start rendering.
#
# == Syntax
#
#   <?if attr ?>
#       ...
#   <?elsif attr ?>
#       ...
#   <?elsif attr.methodchain ?>
#       ...
#   <?end?>
#
class Inversion::Template::ElsifTag < Inversion::Template::AttrTag

	# Inherit AttrTag's tag patterns first.
	inherit_tag_patterns

	# Append a 'not' tag matcher.
	# <?elsif ! foo ?>, <?elsif !foo ?>
	#
	tag_pattern '$(op) sp* $(ident)' do |tag, match|
		op = match.string( 1 )
		raise Inversion::ParseError, "expected '!', got %p instead" % [ op ] unless op == '!'

		tag.send( :log ).debug "  Identifier is: %p (inverted)" % [ match.string(2) ]
		tag.name = match.string( 2 ).to_sym
		tag.inverted = true
	end


	### Create a new ElsifTag.
	def initialize( body, linenum=nil, colnum=nil )
		@inverted = false
		super
	end

	# Invert the tag's renderstate if created with the 'not' operator.
	attr_accessor :inverted


	### Parsing callback -- check to be sure the node tree can have an
	### 'elsif' tag appended to it (i.e., it has an opening 'if' tag).
	def before_appending( parsestate )
		condtag = parsestate.node_stack.reverse.find do |node|
			case node
			when Inversion::Template::IfTag,
			     Inversion::Template::CommentTag
				break node
			when Inversion::Template::ContainerTag
				raise Inversion::ParseError, "'%s' tags can't have '%s' clauses" %
					[ node.tagname.downcase, self.tagname.downcase ]
			end
		end

		unless condtag
			raise Inversion::ParseError, "orphaned '%s' tag" % [ self.tagname.downcase ]
		end
	end


	### Always render as an empty string.
	def render( * )
		nil
	end


	### Toggle rendering for the elsiftag's container if rendering hasn't yet been
	### toggled.
	def before_rendering( renderstate )

		evaluated_state = self.evaluate( renderstate )
		evaluated_state = ! evaluated_state if self.inverted

		if renderstate.tag_data[ :rendering_was_enabled ]
			self.log.debug "Rendering was previously enabled; disabling"
			renderstate.disable_rendering
		elsif evaluated_state
			self.log.debug "Rendering was previously disabled, and condition is true; enabling"
			renderstate.tag_data[ :rendering_was_enabled ] = true
			renderstate.enable_rendering
		end

		return nil
	end

end # class Inversion::Template::ElsifTag

