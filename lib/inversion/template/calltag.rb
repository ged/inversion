#!/usr/bin/env ruby
# vim: set noet nosta sw=4 ts=4 :

require 'inversion/template/attrtag'

# Inversion call tag.
#
# This just exists to make 'call' an alias  for 'attr'.
#
# == Syntax
#
#   <?call foo.bar ?>
#   <?call "%0.2f" % foo.bar ?>

class Inversion::Template::CallTag < Inversion::Template::AttrTag; end

