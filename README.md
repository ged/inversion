# inversion

* http://deveiate.org/projects/Inversion


## Description

Inversion is a templating system for Ruby. It uses the Inversion of Control
principle to decouple the contents and structure of the template from the 
code that uses it, making it easier to use, test-friendly, and clean.


### Details

Inversion, like most other templating systems, works by giving you a way of defining the static parts of your output, and then letting you combine that at a later point with the dynamic parts:

Create the template and use it to render an exciting message:

	tmpl = Inversion::Template.new( "Hello, [?attr name ?]!" )
	tmpl.name = "World"
	puts tmpl.render

The `[?attr name ?]` tag (which can also be written as an XML Processing Instruction, i.e. `<?attr name ?>`) defines the `name` accessor on the template object, the value of which is substituted for any occurances of the `name` tag in the output:

    Hello, World!

This by itself isn't fantastically useful, but it does illustrate one of ways in which Inversion is different: the program and the template share data through an API, instead of through a complex data structure, which establishes a clear delineation between what responsibility is the program's and which is the template's. 

Define a simple email template:

	Dear [?call employee.fullname ?],
	
	Congratulations! You have been selected by [?call failed_company.name ?]'s
	elite management team as one of the many lucky individuals that will
	enjoy the exciting challenge of pursuing other rewarding employment
	opportunities!
	
	Kudos!
	
	You will find your accounts have been disabled, your desk has been helpfully 
	cleared out for you, and all of your personal effects packaged up and
	delivered to your address of record:
	
	[?call employee.address ?]
	
	Please visit your customized Man OverBoard™ transition site immediately:
	
	[?call config.overboard_url ?]/[?urlencode failed_company.id ?]/[?urlencode employee.id ?]
	
	This will acknowledge that you have received this message, and automatically 
	disable your email account.  Be sure and save this message!

	[?if employee.severance_amount.nonzero? ?]
	Failure to acknowledge this message could result in delay of your final 
	severance pay, in the amount of [?call "$%0.2f" % employee.severance_amount ?].
	[?else?]
	Failure to acknowledge this message within 30 days will result in automatic forfeiture of your
	numerous Man Overboard™ package benefits.
	[?end?]
		
	Good Luck,
	Your friends at Spime-Thorpe, Inc!
	http://www.spime-thorpe.com/

Loading this object 


### Tags To Implement

* <?if «conditional expression» ?>…<?elsif «conditional expression» ?>…<?else?>…<?end?>

* <?prettyprint «attr/methodchain» ?>
* <?timedelta «attr/methodchain» ?>
* <?unless «conditional expression» ?>

* <?export «attr» ?>
* <?import «attr» ?>
* <?render «attr/methodchain» AS «identifier» IN «template path» ?>
* <?yield ?>
* <?begin ?>…<?rescue ?>…<?end?>


* <?set  ?>

### Tags Implemented

* <?attr?>
* <?call?>
* <?comment?>…<?end?>
* <?for «Enumerable attr/methodchain» ?>
  <?for obj, i in attr.each_with_index ?>
  <?end?>
* <?config
	  escaping: 'html'
	  ignore_unknown_tags: false
  ?>
* <?include «template path» ?>
* <?escape «attr/methodchain» ?>
* <?urlencode «attr/methodchain» ?>
* <?pp «attr/methodchain» ?>


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

Copyright © 2011, Michael Granger and Mahlon E. Smith
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


