# -*- encoding: utf-8 -*-
# stub: inversion 1.4.0.pre.20221221163546 ruby lib

Gem::Specification.new do |s|
  s.name = "inversion".freeze
  s.version = "1.4.0.pre.20221221163546"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://todo.sr.ht/~ged/Inversion/browse", "documentation_uri" => "http://deveiate.org/code/Inversion", "homepage_uri" => "https://hg.sr.ht/~ged/Inversion", "source_uri" => "https://hg.sr.ht/~ged/Inversion/browse" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze, "Mahlon E. Smith".freeze]
  s.date = "2022-12-21"
  s.description = "Inversion is a templating system for Ruby. It uses the \u201CInversion of Control\u201D principle to decouple the contents and structure of templates from the code that uses them, making it easier to separate concerns, keep your tests simple, and avoid polluting scopes with ephemeral data.".freeze
  s.email = ["ged@faeriemud.org".freeze, "mahlon@martini.nu".freeze]
  s.executables = ["inversion".freeze]
  s.files = ["Examples.md".freeze, "GettingStarted.md".freeze, "Guide.md".freeze, "History.md".freeze, "README.md".freeze, "Tags.md".freeze, "bin/inversion".freeze, "lib/inversion.rb".freeze, "lib/inversion/cli.rb".freeze, "lib/inversion/cli/api.rb".freeze, "lib/inversion/cli/tagtokens.rb".freeze, "lib/inversion/cli/tree.rb".freeze, "lib/inversion/exceptions.rb".freeze, "lib/inversion/mixins.rb".freeze, "lib/inversion/parser.rb".freeze, "lib/inversion/refinements.rb".freeze, "lib/inversion/renderstate.rb".freeze, "lib/inversion/sinatra.rb".freeze, "lib/inversion/template.rb".freeze, "lib/inversion/template/attrtag.rb".freeze, "lib/inversion/template/begintag.rb".freeze, "lib/inversion/template/calltag.rb".freeze, "lib/inversion/template/codetag.rb".freeze, "lib/inversion/template/commenttag.rb".freeze, "lib/inversion/template/configtag.rb".freeze, "lib/inversion/template/containertag.rb".freeze, "lib/inversion/template/defaulttag.rb".freeze, "lib/inversion/template/elsetag.rb".freeze, "lib/inversion/template/elsiftag.rb".freeze, "lib/inversion/template/endtag.rb".freeze, "lib/inversion/template/escapetag.rb".freeze, "lib/inversion/template/fortag.rb".freeze, "lib/inversion/template/fragmenttag.rb".freeze, "lib/inversion/template/iftag.rb".freeze, "lib/inversion/template/importtag.rb".freeze, "lib/inversion/template/includetag.rb".freeze, "lib/inversion/template/node.rb".freeze, "lib/inversion/template/pptag.rb".freeze, "lib/inversion/template/publishtag.rb".freeze, "lib/inversion/template/rescuetag.rb".freeze, "lib/inversion/template/subscribetag.rb".freeze, "lib/inversion/template/tag.rb".freeze, "lib/inversion/template/textnode.rb".freeze, "lib/inversion/template/timedeltatag.rb".freeze, "lib/inversion/template/unlesstag.rb".freeze, "lib/inversion/template/uriencodetag.rb".freeze, "lib/inversion/template/yieldtag.rb".freeze, "lib/inversion/tilt.rb".freeze, "spec/data/sinatra/hello.inversion".freeze, "spec/data/unknown-tag.tmpl".freeze, "spec/helpers.rb".freeze, "spec/inversion/mixins_spec.rb".freeze, "spec/inversion/monkeypatches_spec.rb".freeze, "spec/inversion/parser_spec.rb".freeze, "spec/inversion/renderstate_spec.rb".freeze, "spec/inversion/sinatra_spec.rb".freeze, "spec/inversion/template/attrtag_spec.rb".freeze, "spec/inversion/template/begintag_spec.rb".freeze, "spec/inversion/template/calltag_spec.rb".freeze, "spec/inversion/template/codetag_spec.rb".freeze, "spec/inversion/template/commenttag_spec.rb".freeze, "spec/inversion/template/configtag_spec.rb".freeze, "spec/inversion/template/containertag_spec.rb".freeze, "spec/inversion/template/defaulttag_spec.rb".freeze, "spec/inversion/template/elsetag_spec.rb".freeze, "spec/inversion/template/elsiftag_spec.rb".freeze, "spec/inversion/template/endtag_spec.rb".freeze, "spec/inversion/template/escapetag_spec.rb".freeze, "spec/inversion/template/fortag_spec.rb".freeze, "spec/inversion/template/fragmenttag_spec.rb".freeze, "spec/inversion/template/iftag_spec.rb".freeze, "spec/inversion/template/importtag_spec.rb".freeze, "spec/inversion/template/includetag_spec.rb".freeze, "spec/inversion/template/node_spec.rb".freeze, "spec/inversion/template/pptag_spec.rb".freeze, "spec/inversion/template/publishtag_spec.rb".freeze, "spec/inversion/template/rescuetag_spec.rb".freeze, "spec/inversion/template/subscribetag_spec.rb".freeze, "spec/inversion/template/tag_spec.rb".freeze, "spec/inversion/template/textnode_spec.rb".freeze, "spec/inversion/template/timedeltatag_spec.rb".freeze, "spec/inversion/template/unlesstag_spec.rb".freeze, "spec/inversion/template/uriencodetag_spec.rb".freeze, "spec/inversion/template/yieldtag_spec.rb".freeze, "spec/inversion/template_spec.rb".freeze, "spec/inversion/tilt_spec.rb".freeze, "spec/inversion_spec.rb".freeze]
  s.homepage = "https://hg.sr.ht/~ged/Inversion".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.rubygems_version = "3.3.7".freeze
  s.summary = "Inversion is a templating system for Ruby.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<loggability>.freeze, ["~> 0.17"])
    s.add_runtime_dependency(%q<sysexits>.freeze, ["~> 1.2"])
    s.add_runtime_dependency(%q<gli>.freeze, ["~> 2.21"])
    s.add_runtime_dependency(%q<tty-prompt>.freeze, ["~> 0.23"])
    s.add_runtime_dependency(%q<pastel>.freeze, ["~> 0.8"])
    s.add_development_dependency(%q<rack-test>.freeze, ["~> 1.1"])
    s.add_development_dependency(%q<rake-deveiate>.freeze, ["~> 0.21"])
    s.add_development_dependency(%q<rdoc>.freeze, ["~> 6.2"])
    s.add_development_dependency(%q<rdoc-generator-sixfish>.freeze, ["~> 0.1"])
    s.add_development_dependency(%q<rspec-wait>.freeze, ["~> 0.0"])
    s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.18"])
    s.add_development_dependency(%q<sinatra>.freeze, ["~> 2.0"])
    s.add_development_dependency(%q<tilt>.freeze, ["~> 2.0"])
    s.add_development_dependency(%q<safe_yaml>.freeze, ["~> 1.0"])
  else
    s.add_dependency(%q<loggability>.freeze, ["~> 0.17"])
    s.add_dependency(%q<sysexits>.freeze, ["~> 1.2"])
    s.add_dependency(%q<gli>.freeze, ["~> 2.21"])
    s.add_dependency(%q<tty-prompt>.freeze, ["~> 0.23"])
    s.add_dependency(%q<pastel>.freeze, ["~> 0.8"])
    s.add_dependency(%q<rack-test>.freeze, ["~> 1.1"])
    s.add_dependency(%q<rake-deveiate>.freeze, ["~> 0.21"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 6.2"])
    s.add_dependency(%q<rdoc-generator-sixfish>.freeze, ["~> 0.1"])
    s.add_dependency(%q<rspec-wait>.freeze, ["~> 0.0"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.18"])
    s.add_dependency(%q<sinatra>.freeze, ["~> 2.0"])
    s.add_dependency(%q<tilt>.freeze, ["~> 2.0"])
    s.add_dependency(%q<safe_yaml>.freeze, ["~> 1.0"])
  end
end
