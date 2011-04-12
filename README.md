# inversion

* http://deveiate.org/projects/Inversion


## Description

Inversion is a templating system for Ruby that uses the Inversion of Control 
principle to decouple the contents and structure of the template from the 
code that uses it It is intended for use as a Passive View by implementations 
of the Supervising Controller pattern.


### Details

Setting data values in an Inversion template is accomplished using Ruby
attribute methods on the template object, rather than intermediate data
structures that is combined with the template when it's rendered. This allows
the programmer to add data directly and individually from whatever part of the
code it is generated, by the systems which generate it, rather than requiring
that all code that affects rendering be written with the intermediate data
structures in mind. The template object itself can be passed around without
sacrificing encapsulation or exposing unnecessary scope.

The scope of the template object when it's being rendered is not shared with the
code that uses it, or vice-versa, in contrast to many modern implementations of
Model-View-Controller. This encourages proper separation of responsibility and
makes it possible to test the Controller and View independently.

For instance, ERB templates such as those used by Ruby on Rails' Action View are
rendered by evaluating them in the Binding of their caller. This means that the
controller must be explicitly aware of the variables and data structures
required by the template, making it impossible, or at least impractical, to test
either part in isolation.

It also means that changes to state that happen in the template bleed over into
the state of the controller. This is often used to introduce side-effects while
rendering the template, further coupling the presentation layer to the
controlling layer.

	#!/usr/bin/env ruby
	require 'erb'
	
	TEMPLATE = <<END_TEMPLATE
	<% var = "foo" %>
	END_TEMPLATE
	 
	var = 1
	template = ERB.new( TEMPLATE )
	   
	puts "Before rendering, var = %p" % [ var ]
	output = template.result( binding() )
	puts "After rendering, var = %p" % [ var ]

This outputs:
 
	$ ruby experiments/erb_scope_bleed.rb 
	Before rendering, var = 1
	After rendering, var = "foo"

[...more examples forthcoming...]


## References

* Inversion of Control: http://en.wikipedia.org/wiki/Inversion_of_control
* Passive View: http://martinfowler.com/eaaDev/PassiveScreen.html
* Supervising Controller: http://martinfowler.com/eaaDev/SupervisingPresenter.html


## Installation

    gem install inversion


## Contributing

You can check out the current development source [with Mercurial][hgrepo], or
if you prefer Git, via the project's [Github mirror][gitmirror].

You can submit bug reports, suggestions, and read more about future plans at
[the project page][projectpage].

After checking out the source, run:

	$ rake newb

This task will install any missing dependencies, run the tests/specs,
and generate the API documentation.


## License

Copyright (c) 2011, Michael Granger
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


[hgrepo]: http://repo.deveiate.org/Inversion
[gitmirror]: git://github.com/ged/Inversion.git
[projectpage]: http://deveiate.org/projects/Inversion


