# Getting Started

## Requirements

- Ruby 2.7.5 or later


## Installation

    $ gem install inversion


## Basic Usage

Inversion, like most other templating systems, works by giving you a way of
defining the static parts of your output, and then letting you combine that at
a later point with the dynamic parts:

Create the template and use it to render an exciting message:

    tmpl = Inversion::Template.new( "Hello, <?attr name ?>!" )
    tmpl.name = "World"
    puts tmpl.render

The `<?attr name ?>` tag defines the _name_ accessor on the
[template](rdoc-ref:Templates) object, the value of which is substituted for
any occurrences of `name` in the template:

    Hello, World!

This by itself isn't fantastically useful, but it does illustrate one of the
ways in which Inversion is different: the program and the template share data
through an API, instead of through a complex data structure, which establishes
a clear delineation between what responsibility is the program's and which is
the template's. The program doesn't have to know how the view uses the data
it's given, and tests of the controller can substitute a Mock Object for the
template to test the interaction between the two instead of having to match
patterns in the eventual output like an integration test.

You can also interact with the values set in the template:

    Name: <?attr employee.full_name ?>

This will call the #full_name method on whatever is set as the `employee`
attribute when rendered, and the result will take the place of the tag.

Inversion also comes with a collection of [other tags](rdoc-ref:Tags) that
provide flow control, exception-handling, etc.


