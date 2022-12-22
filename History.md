# Release History for inversion

---

## v1.4.0 [2022-12-21] Michael Granger <ged@faeriemud.org>

Improvements:

- Update for Ruby 3, modernize RSpec setup
- Convert CLI to GLI+TTY
- Fix up error class in codetag.


## v1.3.1 [2020-09-29] Michael Granger <ged@faeriemud.org>

Improvements:

- Only use SafeYAML if it's already loaded
- Handle HTML encoding for uriencoding tag ourselves


## v1.3.0 [2020-04-08] Mahlon E. Smith <mahlon@martini.nu>

- Use safe_yaml when deserializing config tag contents.
- Un-hoeify.
- Updates for Ruby 2.7.


## v1.2.0 [2019-05-14] Michael Granger <ged@FaerieMUD.org>

Enhancements:

- Add frozen string literal support (Ruby 2.6+)
- Allow the timedelta tag to accept hash arguments and make
  'decorators' optional.


## v1.1.1 [2017-11-13] Michael Granger <ged@FaerieMUD.org>

Bugfixes:

- Yield subarrays in `each` tags when there's only one block argument (#3).


## v1.1.0 [2017-08-17] Mahlon E. Smith <mahlon@martini.nu>

Enhancements:

- Allow the use of the '!' operator in conditional tags, logically
  inverting the evaluated body.

- Provide a method for children tags to inherit and append to their
  parents matcher patterns.


## v1.0.0 [2017-01-16] Michael Granger <ged@FaerieMUD.org>

Mark as stable, update dependencies.


## v0.18.0 [2015-10-01] Michael Granger <ged@FaerieMUD.org>

Add a `strict_attributes` option for templates.


## v0.17.4 [2015-07-08] Michael Granger <ged@FaerieMUD.org>

Fixes:

- Make 'default' tag not override `false` values. Thanks to Rob
  Galanakis <rob.galanakis@gmail.com>.


## v0.17.3 [2015-02-16] Michael Granger <ged@FaerieMUD.org>

- Performance fix: Re-comment the #inspect logging message
  in the RenderState
- Updated tag docs


## v0.17.2 [2015-01-22] Michael Granger <ged@FaerieMUD.org>

- Fix a bug with the fragment tag.

Fragments will now propagate to the container template when they're
added by inner templates.


## v0.17.1 [2015-01-15] Michael Granger <ged@FaerieMUD.org>

Re-push to fix a misbuilt gem.


## v0.17.0 [2015-01-15] Michael Granger <ged@FaerieMUD.org>

Support snakecase tag names/tag filenames


## v0.16.0 [2015-01-14] Michael Granger <ged@FaerieMUD.org>

Add support for loading templates from an alternate path
via :template_paths option to Inversion::Template.load.


## v0.15.0 [2014-11-24] Michael Granger <ged@FaerieMUD.org>

Add a mechanism to allow tags to extend the template.


## v0.14.0 [2014-11-05] Michael Granger <ged@FaerieMUD.org>

- Add the fragment tag and docs
- Remove old manual doc artifacts. Add documentation for the
  'begin/rescue' and 'default' tags.


## v0.13.0 [2014-04-23] Michael Granger <ged@FaerieMUD.org>

- Carry global configuration into instantiated template options.
- Documentation update.

(Never released.)


## v0.12.3 [2013-09-20] Michael Granger <ged@FaerieMUD.org>

- Don't deep_copy IOs or Tempfiles (bugfix).


## v0.12.2 [2013-06-19] Michael Granger <ged@FaerieMUD.org>

- Fix propagation of config tags into subtemplates (fixes #1)
- Use replacement in transcoding instead of raising encoding errors


## v0.12.1 [2013-03-05] Michael Granger <ged@FaerieMUD.org>

A bunch of optimization and inspect-encoding fixes.


## v0.12.0 [2013-03-01] Michael Granger <ged@FaerieMUD.org>

- Make exceptions rendered as comments include the backtrace if
  debugging comments are enabled.


## v0.11.2 [2012-09-17] Michael Granger <ged@FaerieMUD.org>

- [bugfix] Don't cast enumerated values in for tags to Arrays.


## v0.11.1 [2012-09-17] Michael Granger <ged@FaerieMUD.org>

- [bugfix] Make subscriptions get nodes that were already published


## v0.11.0 [2012-07-06] Michael Granger <ged@FaerieMUD.org>

- Automatically transcode output according to the registered encoding
  if the template is created with one


## v0.10.2 [2012-06-27] Mahlon E. Smith  <mahlon@martini.nu>

- Bugfix: Don't dup Classes and Modules in template attributes.
- Optimization: Don't needlessly duplicate the node tree on template
  duplication.


## v0.10.1 [2012-06-22] Michael Granger <ged@FaerieMUD.org>

- Bugfix: duplicated templates get distinct copies of their attributes.


## v0.10.0 [2012-05-07] Michael Granger <ged@FaerieMUD.org>

- Added signature for changeset 9d9c49d532be

## v0.10.0 [2012-05-07] Michael Granger <ged@FaerieMUD.org>

- Convert to Loggability for logging.


## v0.9.0 [2012-04-24] Michael Granger <ged@FaerieMUD.org>

- Split the template path out from the config into a class instance variable.
- Documentation update.


## v0.8.0 [2012-04-01] Michael Granger <ged@FaerieMUD.org>

- Optimization fixes
- Fixed rendering flow control to not use a begin/rescue.


## v0.7.0 [2012-03-29] Michael Granger <ged@FaerieMUD.org>

- Switch to a much more flexible way to render tag bodies. This should
  resolve most of the problems we've encountered with complex templates.


## v0.6.1 [2012-03-16] Michael Granger <ged@FaerieMUD.org>

- Commented out some of the more expensive debug logging for an order
  of magnitude increase in render speed.


## v0.6.0 [2012-03-13] Michael Granger <ged@FaerieMUD.org>

- Fix a bug with "for" tag iteration over complex data structures
- Add a configurable delay for checking for changes on file-based
  templates to avoid a stat() per request.
- Carry options that are set in the global configuration across to the
  parser.
- Handle Configurability's configure-with-defaults call.


## v0.5.0 [2012-01-05] Michael Granger <ged@FaerieMUD.org>

Added an encoding option to Inversion::Template.load for
specifying the encoding of the template source.


## v0.4.0 [2011-10-05] Michael Granger <ged@FaerieMUD.org>

Reworked render toggling so the before/after rendering hooks are
called immediately before and after the node *would* have been
rendered. This further cleans up the conditional logic, and causes
the if/elsif/else tags to behave like you'd expect: the nodes they
demark aren't even touched if rendering is disabled.

Adjusted the other tags to account for the change.


## v0.3.0 [2011-10-05] Michael Granger <ged@FaerieMUD.org>

- Fix require loop in if/elsif tags
- Fixing a problem with HTML escaping of objects other than Strings
- Added render timing (Inversion::RenderState#time_elapsed)


## v0.2.0 [2011-09-27] Michael Granger <ged@FaerieMUD.org>

- Bugfixes (#1, #2)
- Renamed Inversion::Template::Parser to Inversion::Parser
- Added RenderState#tag_state for tracking tag state on a
  per-render basis.


## v0.1.1 [2011-09-23] Michael Granger <ged@FaerieMUD.org>

- Bugfix for the Subscribe tag.


## v0.1.0 [2011-09-23] Michael Granger <ged@FaerieMUD.org>

- Added template reloading via Inversion::Template#changed?
  and #reload.


## v0.0.4 [2011-09-21] Michael Granger <ged@FaerieMUD.org>

- Avoid Pathname#expand_path in Inversion::Template.load
  [optimization]
- Fix circular require in inversion/template/elsiftag.rb.
- Fix a shadowed variable in BeginTag#handle_exception.
- Added a manual


## v0.0.3 [2011-08-15] Michael Granger <ged@FaerieMUD.org>

- Dependency fix


## v0.0.2 [2011-08-15] Michael Granger <ged@FaerieMUD.org>

- Packaging fix


## v0.0.1 [2011-02-02] Michael Granger <ged@FaerieMUD.org>

Initial release.

