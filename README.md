# inversion

home
: https://hg.sr.ht/~ged/Inversion

code
: https://hg.sr.ht/~ged/Inversion/browse

github
: https://github.com/ged/inversion

docs
: http://deveiate.org/code/inversion


## Description

Inversion is a templating system for Ruby. It uses the "Inversion of Control"
principle to decouple the contents and structure of templates from the code
that uses them, making it easier to separate concerns, keep your tests simple,
and avoid polluting scopes with ephemeral data.


### Details

Inversion, like most other templating systems, works by giving you a way of
defining the static parts of your output, and then letting you combine that at
a later point with the dynamic parts:

Create the template and use it to render an exciting message:

    tmpl = Inversion::Template.new( "Hello, <?attr name ?>!" )
    tmpl.name = "World"
    puts tmpl.render

The `<?attr name ?>` tag defines the _name_ accessor on the template
object, the value of which is substituted for any occurrences of `name` in the
template:

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

Inversion also comes with [a collection of other tags](rdoc-ref:Tags) that
provide flow control, exception-handling, etc.

Here's a slightly more complex example: Say we have a layout template that
contains all the boilerplate, navigation, etc. for the site, and then an
`<?attr body ?>` somewhere in the content area for the content specific to
each view:

    layout = Inversion::Template.load( 'templates/layout.tmpl' )

Then there's a view template that displays a bulleted list of article titles:
 
    <!-- articlelist.tmpl -->
    <section id="articles">
      <ul>
      <?for article in articles ?>
        <li><?call article.title ?></li>
      <?end for ?>
      </ul>
    </section>

Loading this template results in a Ruby object whose API contains one method:
`#articles`. To render the view, we just call that accessor with instances of
an `Article` domain class we defined elsewhere, and then drop the `alist`
template into the layout and render them:

    alist = Inversion::Template.load( 'templates/alist.tmpl' )
    alist.articles = Articles.latest( 10 )
    
    layout.body = alist
    puts layout.render

The `for` tag in the alist will iterate over the enumerable Articles and
generate an `<li>` for each one. The resulting template object will be set as
the body of the layout template, and stringified when the enclosing template
is rendered. Templates can be nested this way as deeply as you like.

For detailed tag documentation and examples, start with the Inversion::Template
class in the API documentation.


## References

* Inversion of Control - https://en.wikipedia.org/wiki/Inversion_of_control
* Passive View - https://martinfowler.com/eaaDev/PassiveScreen.html
* Supervising Controller - https://martinfowler.com/eaaDev/SupervisingPresenter.html


## Installation

    gem install inversion


## Contributing

You can check out the current development source
[with Mercurial](https://hg.sr.ht/~ged/Inversion), or if you prefer Git, via the
project's [Github mirror](https://github.com/ged/Inversion).

You can submit bug reports, suggestions, and read more about future plans at
[the project page](https://hg.sr.ht/~ged/Inversion).

After checking out the source, run:

    $ gem install -Ng
    $ rake setup

This task will install any missing dependencies and do any necessary developer
setup.


## Authors

* Michael Granger <ged@faeriemud.org>
* Mahlon E. Smith <mahlon@martini.nu>


## License

Copyright © 2011-2022, Michael Granger and Mahlon E. Smith
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the author/s, nor the names of the project's
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



