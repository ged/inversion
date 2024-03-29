# Built-In Tags

Inversion's tags support the [Pluggability](http://rubygems.org/gems/pluggability) API, allowing for the easy addition of [custom tags](#label-Custom+Tags), but it comes with a number of built-in ones too.


## Tag Syntax

Tags can be in either of two formats:

- XML Pre-processing instruction style: `<?tagname tagdata ?>`
- or the same thing, but with square brackets instead: `[?tagname tagdata ?]`

The second form is especially useful if you're generating HTML and want to put an Inversion tag inside the attribute of an HTML tag, but still want the template to be well-formed:

    <a href="[?call article.permalink ?]">Permalink</a>

You can mix tag forms in a single document.


## Placeholder Tags

Placeholder tags represent the main functionality of Inversion; they create a placeholder in the output text which can be filled in via a method on the template object with the same name.


### `attr`

The `attr` tag is the primary placeholder tag for injecting dynamic values into your templates.  The most basic form is analogous to `attr_accessor`; it defines a method on the template object that, when set, replaces all occurrences of the tag in the template with the value:

    Title: <?attr title ?>

Calling the template object's `#title=` method will inject the stringified value into that part of the output when it's rendered, e.g.,

    template.title = "How to Breed Kangaroos for Milk and Meat"
    template.render
    # => "Title: How to Breed Kangaroos for Milk and Meat"

The rendered values of an `attr` tag can also be the result of calling methods on the attr value:

    ISBN: <?attr book.isbn ?>

Attributes can be sprintf formatted using Ruby's String#% method:

    Book price: <?attr "%0.2f" % book.price ?>

Attributes can also contain other template objects, which allows templates to be nested within each other easily.

    layout  = Inversion::Template.load( 'layout.tmpl' )
    content = Inversion::Template.load( 'content.tmpl' )
    content.caption = "Your kids will love their new Kangaroo family!"
    layout.body = content
    layout.render


### `call`

`call` is just an alias for `attr`.  Use whichever strikes your fancy.


### `escape`

`escape` works just like `attr`, but it escapes the content inserted into the template, using the configured escaping behavior.  The supported escaping behaviors are defined in a mixin called Inversion::Escaping. The behavior to use can be set using the [:escape_format](Templates@Template`Options) option on the template or in a `config+ tag; it defaults to HTML escaping.

    <p>Company name: <?escape company.name ?></p>

If the company was `"AT&T"`, the output would look like:

    <p>Company name: AT&amp;T</p>


### `uriencode`

The `urlencode` tag is another `attr`-like tag, but this one does URI encoding:

    <nav>Edit <a href="/profile?name=[?uriencode person.name ?]">your profile</a></nav>


## Special Placeholders

### `timedelta`

If you need to automatically generate a human-readable description of the interval between two times, you can use the `timedelta` tag:

    <article class="blogentry">
        <header>
            <p>Posted: <?timedelta entry.date_posted ?>.</p>
        </header>
        ...
    </article>

The tag supports any object which responds to the `#to_time` method, so standard `Time`, `Date`, and `DateTime` objects all work.

Dates are compared against the current time, and render to approximate descriptions of the interval, e.g.,

* 4 days ago
* about an hour from now
* 6 weeks ago
* less than a minute from now


## Inter-template Tags

These tags operate on nested templates, allowing you to selectively use or send attributes or content from other templates.


### `import`

Occasionally, you'll want to compose output from several different templates by nesting them, but you don't want to have to set common objects on all of them from code. The `import` tag lets you copy the values from a container template into one intended to be nested within it:

    <!-- layout.tmpl -->
    Logged in as: <?attr request.authenticated_user ?>
    <?attr body ?>

    <!-- body.tmpl -->
    <?import request ?>
    <p>You can check your balance using <a href="[?call request.path_info ?]/accounts">the
       accounts tool</a>.</p>

When the content template is nested in the container, you only need to set the `request` attribute on the container to set it in both places:

    layout = Inversion::Template.load( 'layout.tmpl' )
    body = Inversion::Template.load( 'body.tmpl' )

    layout.body = body
    layout.request = request

    puts layout.render

Without the use of `import`, you'd need to similarly set the request attribute on the body template.

The imported attribute's value is determined at render time, so you can also use it to import values from an iteration.

    <!-- Container template (table.tmpl)" -->
    <table>
      <thead>...</thead>
      <tbody>
        <?for user in assigned_users ?>
        <?attr row ?>
        <?end for ?>
      </tbody>
    </table>
    <?end?>

    <!-- Content template (row.tmpl)" -->
    <?import user ?>
        <tr>
          <th>Username:</th><td><?escape user.username ?></td>
          <th>UID:</th><td><?escape user.uid ?></td>
          <th>GID:</th><td><?escape user.gid ?></td>
        </tr>
    <?end?>

and the code:

    usertable = Inversion::Template.load( 'table.tmpl' )
    userrow = Inversion::Template.load( 'row.tmpl' )

    usertable.row = userrow
    usertable.assigned_users = User.assigned.all

    puts usertable.render

When the `row.tmpl` is rendered each time, its imported `user` is set to whatever the `user` in the container is, in this case the next object in `assigned_users`.

You can import values into deeply-nested templates, provided each container imports it as well.


### `publish`/`subscribe`

Often you'll want to set up a generic layout template to establish a global look-and-feel, and then modify it based on the content of an inner template.

#### Look and feel template (`layout.tmpl`)

    <!DOCTYPE HTML>
    <html lang="en">
    <head>
      <title><?subscribe title || Untitled ?></title>
      <link rel="stylesheet" href="/css/base.css" type="text/css" media="screen"
        title="Base Stylesheet" charset="utf-8" />
        <?subscribe stylesheets ?>

      <script defer="defer" src="/js/jquery-1.4.2.min.js"
          type="text/javascript" charset="utf-8"></script>
        <?subscribe scripts ?>
    </head>

    <body><?attr body ?></body>
    </html>


#### A content template (`content.tmpl`)

    <?publish title ?>I make stuff up<?end publish?>

    <?publish stylesheets ?>
      <link rel="stylesheet" href="/css/content.css" type="text/css" media="screen"
        title="Content Style Overrides" charset="utf-8" />
    <?end publish?>

    <?publish scripts ?>
      <script defer="defer" src="/js/content.js" type="text/javascript" charset="utf-8"></script>
    <?end publish?>

    <div>Hi, there.</div>

#### Template setup

    layout  = Inversion::Template.load( 'layout.tmpl' )
    content = Inversion::Template.load( 'content.tmpl' )

    layout.body = content

    puts layout.render

`subscribe` renders to an empty string if there is no matching `publish`, or to the value of a default if supplied (as in the HTML title example above.)
In this fashion, you can dynamically switch out different content pages, with each having the ability to optionally override various HTML elements.

### `include`

The `include` tag allows inclusion of other template files from within a template.  This supports separation of a template into several reusable components.  The included template becomes a part of the including template, along with any defaults, attributes and configuration.

#### `include` setup

    email = Inversion::Template.load( 'email.tmpl' )

    email.greeting = "Kudos"
    email.company  = Company[ :spime_thorpe ]
    email.user     = User[ :jrandom ]

    puts main.render

#### Including template (`email.tmpl`)

    Subject: Great news, everybody!
    From: <?attr company.email ?>
    To: <?attr user.email ?>

    <?attr greeting ?>, <?attr user.first_name ?>!

    We are excited to inform you that you have been selected to participate
    in a challenging and exciting career displacement opportunity!

    Please attend the mandatory Man Overboard (tm) session we have scheduled
    for you at 8:45AM on Thursday in the Sunshine Room. Light refreshments
    and computer-aided aptitude testing will be provided.

    <?include signature.tmpl ?>

#### Included template (`signature.tmpl`)

    Sincerely,
    Your Friends at <?attr company.name ?>!

#### The rendered output

    Subject: Great news, everybody!
    From: "Spime-Thorpe, Inc." <salesteam2@spime-thorpe.com>
    To: "James Random" <jrandom@compusa.com>

    Kudos, James!

    We are excited to inform you that you have been selected to participate
    in a challenging and exciting career displacement opportunity!

    Please attend the mandatory Man Overboard (tm) session we have scheduled
    for you at 8:45AM on Thursday in the Sunshine Room. Light refreshments
    and computer-aided aptitude testing will be provided.

    Sincerely,
    Your Friends at Spime Thorpe!


### `fragment`

A `fragment` tag also sets an attribute from within the template, but under the
scope of the global template itself. A fragment can use other Inversion tags,
and the attribute is both usable elsewhere in the template, and accessible from
calling code after rendering.

    template = Inversion::Template.new <<-TMPL
    <?fragment subject ?>Your order status (Order #<?call order.number ?>)<?end ?>

    Dear <?call order.customer.name ?>,

    Your recent order was modified by our Order Fulfillment Team.

    After careful deliberation, it was decided that no one should have need for that many hot dogs
    with overnight shipping.  Frankly, we're more than a little concerned for your health.

    Sincerely,
    Rowe's Meat Emporium
    (Buy!  Sell!  Consignment!)
    TMPL

    template.order = order
    template.render

    template.fragments[ :subject ] #=> "Your order status (Order #3492)"


## Flow Control

The following tags are used to alter the flow of rendering from within templates.


### `for`

The `for` tag iterates over the objects in a collection, rendering its
template section once for each iteration. Its attribute can be set to anything
that responds to @#each@. The iteration variable(s) are scoped to the block,
and temporarily override any template attributes of the same name.

#### `for` tag setup

    overhead_list = Inversion::Template.load( 'employee_list.tmpl' )
    overhead_list.users = User.
      filter { start_date < 6.months.ago }.
      filter { department = 'Information Technology' }

    puts overhead_list.render

The `for` tag's iteration works just like Ruby's `for`; if the enumerated
value has more than one value, you can give a list of iteration variables to
be assigned to.

#### Employee list using `for`

    <table>
      <thead>...</thead>
      <tbody>
        <?for user, i in users.each_with_index ?>
            <tr class="[?if i.even? ?]even[?else?]odd[?end if?]-row">
                <td><?attr user.first_name ?></td>
                <td><?attr user.last_name ?></td>
                <td><?attr user.title ?></td>
                <td><?attr user.start_date ?></td>
                <td><?attr user.salary ?></td>
            </tr>
        <?end for ?>
      </tbody>
    </table>

The example above uses a Ruby enumerator for the `#each_with_index` method to set the class of the row to `'even-row'` or `'odd-row'`.

This works with the keys and values of Hashes, too:

#### Display hash of notes keyed by author using `for`

    <?for user, content in user.notes ?>
    <section class="note">
      <header>
        Note by <?call user.username ?>
      </header>
      <p><?escape content ?></p>
    </section>

    <?end for ?>

Note that you can also use Ruby's "external iterator" syntax to iterate, too:

#### Iterate over each byte of a string with an index using `for`

    <section class="hexdump">
    <?for byte, index in frame.header.each_byte.with_index ?>
      <?if index.modulo(8).zero? ?>
        <?if index.nonzero? ?>
      </span><br />
        <?end if ?>
      <span class="row"><?attr "0x%08x" % index ?>:
      <?end if ?>
      &nbsp;`<?attr "0x%02x" % byte ?>`
    <?end for ?>
    </section>



### `if`/`elsif`/`else`

The `if` tag can be used to conditionally render a section of the template based on the value of an attribute or the value of a method called on it.

#### Conditional block

    <?if user.has_stock_options? ?>
    You will have 21 days to exercise your stock options.
    <?else ?>
    You have a week to optionally take home a handful of supplies from the
    office cabinet.
    <?end if ?>


### `unless`

Unless is like the `if` tag, but with inverted logic. Note that an `unless` can have an `else` tag, but cannot have any `elsif` tags within it.


### `yield`

The `yield` tag is used to defer rendering of some part of the template to the code that is calling render[rdoc-ref:Inversion::Template#render] on it. If a block is passed to `#render`, then the `yield` tag will call it with the Inversion::RenderState object that is currently in effect, and will render the return value in its place.

#### Using `yield` to defer an expensive database lookup (`report.tmpl`)

    <?if extra_details_enabled ?>
    <?yield ?>
    <?end if ?>

    report = Inversion::Template.load( 'report.tmpl' )
    report.extra_details_enabled = true if $DEBUG
    puts report.render do
      report_table = Inversion::Template.load( 'table.tmpl' )
      report_table.rows = an_expensive_database_query()
      report_table
    end

This will insert the `report_table` template in place of the yield, but only if $DEBUG is true.


### `begin`/`rescue`

These tags work as you'd expect from their ruby counterparts.

The `begin` section of the template to be rendered only if no exceptions are raised while it's
being rendered. If an exception is raised, it is checked against any `rescue` sections, and the
first with a matching exception is rendered instead. If no `rescue` block is found, the exception
is handled by the configured exception behavior for the template (see Inversion::Template@Template+Options).

    <?begin ?><?call employees.length ?><?end?>

    <?begin ?>
      <?for employee in employees.all ?>
        <?attr employee.name ?> --> <?attr employee.title ?>
      <?end for?>
    <?rescue DatabaseError => err ?>
      Oh no!! I can't talk to the database for some reason.  The
      error was as follows:
      <pre>
        <?attr err.message ?>
      </pre>
    <?end?>


## Control Tags

There are a few tags that can be used to set values in the templating system itself.

### `config`

The `config` tag can be used to override template options[Templates@Template+Options]
on a per-template basis.  It allows for convenient, inline settings from
within a template rather than from the code in which the template is
loaded.

For example, if you want to enable debugging comments on a single template:

    <?config debugging_comments: true ?>

Multiple template options can be set simultaneously by using a YAML hash:

    <?config
        on_render_error: propagate
        debugging_comments: true
        comment_start: /*
        comment_end: */
    ?>

Note that this also allows you to set multiple options on a single line, if you wrap them in braces:

    <?config { comment_start: "/*", comment_end: "*/" } ?>


### `default`

The `default` tag sets an attribute from within the template,
and this value is used if the attribute is set to nil or otherwise unset.

    template = Inversion::Template.new <<-TMPL
      <?default adjective to "cruel" ?>
      <?default noun to "world" ?>
      Goodbye, <?attr adjective ?> <?attr noun ?>!
    TMPL

    template.render

    template.adjective = "delicious"
    template.render

    template.adjective = nil
    template.noun = "banana"
    template.render

Would produce the output:

    Goodbye, cruel world!
    Goodbye, delicious world!
    Goodbye, cruel banana!



## Troubleshooting/Introspection

### `pp`

The `pp` tag uses the `PP` library to output an escaped representation of its argument.

#### Creating an object to inspect

    content = Inversion::Template.load( 'content.tmpl' )
    content.file = File.stat( '/tmp/example.txt' )

    puts content.render

#### Inspecting an object from within a template (`content.tmpl`)

    <div class="debugging">
        The file's stat attributes:
        <?pp file ?>
    </div>

The output is escaped according to the current setting of the [:escape_format](rdoc-ref:Templates@Template+Options) option.

#### The rendered result

    <div class="debugging">
        The file's stat attributes:
            #&lt;File::Stat
     dev=0xe000004,
     ino=3064556,
     mode=0100644 (file rw-r--r--),
     nlink=1,
     uid=501 (mahlon),
     gid=0 (wheel),
     rdev=0x0 (0, 0),
     size=0,
     blksize=4096,
     blocks=0,
     atime=2011-08-12 08:43:15 -0700 (1313163795),
     mtime=2011-08-12 08:43:15 -0700 (1313163795),
     ctime=2011-08-12 08:43:15 -0700 (1313163795)&gt;</div>
    </div>


## Custom Tags

We have a lot of documentation work to do for this still, but the basics are:

* Create a file with the path `lib/inversion/template/«yourtagnametag».rb/code>
* Name your class Inversion::Template::«yourtagname.capitalize»Tag
* Subclass one of the abstract template tag types:
  * If your tag body will contain code, subclass Inversion::Template::CodeTag
  * Otherwise, subclass Inversion::Template::Tag
* If your tag is a container, include Inversion::Template::ContainerTag
* Read the documentation for the tag type you're subclassing for the methods
  you're required to implement.

Unfortunately, the tag superclasses aren't currently documented very well, so
the best way to accomplish what you want is to find an existing tag that does
something similar and look at how it does it.
