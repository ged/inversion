# -*- encoding: utf-8 -*-
# stub: inversion 0.17.2.pre20150216161946 ruby lib

Gem::Specification.new do |s|
  s.name = "inversion"
  s.version = "0.17.3"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Michael Granger", "Mahlon E. Smith"]
  s.date = "2015-02-17"
  s.description = "Inversion is a templating system for Ruby. It uses the \"Inversion of Control\"\nprinciple to decouple the contents and structure of templates from the code\nthat uses them, making it easier to separate concerns, keep your tests simple,\nand avoid polluting scopes with ephemeral data."
  s.email = ["ged@FaerieMUD.org", "mahlon@martini.nu"]
  s.executables = ["inversion"]
  s.extra_rdoc_files = ["Examples.rdoc", "GettingStarted.rdoc", "Guide.rdoc", "History.rdoc", "Manifest.txt", "README.rdoc", "Tags.rdoc", "README.rdoc", "History.rdoc"]
  s.files = ["ChangeLog", "Examples.rdoc", "GettingStarted.rdoc", "Guide.rdoc", "History.rdoc", "Manifest.txt", "README.rdoc", "Rakefile", "Tags.rdoc", "bin/inversion", "lib/inversion.rb", "lib/inversion/exceptions.rb", "lib/inversion/mixins.rb", "lib/inversion/monkeypatches.rb", "lib/inversion/parser.rb", "lib/inversion/renderstate.rb", "lib/inversion/sinatra.rb", "lib/inversion/template.rb", "lib/inversion/template/attrtag.rb", "lib/inversion/template/begintag.rb", "lib/inversion/template/calltag.rb", "lib/inversion/template/codetag.rb", "lib/inversion/template/commenttag.rb", "lib/inversion/template/configtag.rb", "lib/inversion/template/containertag.rb", "lib/inversion/template/defaulttag.rb", "lib/inversion/template/elsetag.rb", "lib/inversion/template/elsiftag.rb", "lib/inversion/template/endtag.rb", "lib/inversion/template/escapetag.rb", "lib/inversion/template/fortag.rb", "lib/inversion/template/fragmenttag.rb", "lib/inversion/template/iftag.rb", "lib/inversion/template/importtag.rb", "lib/inversion/template/includetag.rb", "lib/inversion/template/node.rb", "lib/inversion/template/pptag.rb", "lib/inversion/template/publishtag.rb", "lib/inversion/template/rescuetag.rb", "lib/inversion/template/subscribetag.rb", "lib/inversion/template/tag.rb", "lib/inversion/template/textnode.rb", "lib/inversion/template/timedeltatag.rb", "lib/inversion/template/unlesstag.rb", "lib/inversion/template/uriencodetag.rb", "lib/inversion/template/yieldtag.rb", "lib/inversion/tilt.rb", "spec/data/sinatra/hello.inversion", "spec/data/unknown-tag.tmpl", "spec/helpers.rb", "spec/inversion/mixins_spec.rb", "spec/inversion/monkeypatches_spec.rb", "spec/inversion/parser_spec.rb", "spec/inversion/renderstate_spec.rb", "spec/inversion/sinatra_spec.rb", "spec/inversion/template/attrtag_spec.rb", "spec/inversion/template/begintag_spec.rb", "spec/inversion/template/calltag_spec.rb", "spec/inversion/template/codetag_spec.rb", "spec/inversion/template/commenttag_spec.rb", "spec/inversion/template/configtag_spec.rb", "spec/inversion/template/containertag_spec.rb", "spec/inversion/template/defaulttag_spec.rb", "spec/inversion/template/elsetag_spec.rb", "spec/inversion/template/elsiftag_spec.rb", "spec/inversion/template/endtag_spec.rb", "spec/inversion/template/escapetag_spec.rb", "spec/inversion/template/fortag_spec.rb", "spec/inversion/template/fragmenttag_spec.rb", "spec/inversion/template/iftag_spec.rb", "spec/inversion/template/importtag_spec.rb", "spec/inversion/template/includetag_spec.rb", "spec/inversion/template/node_spec.rb", "spec/inversion/template/pptag_spec.rb", "spec/inversion/template/publishtag_spec.rb", "spec/inversion/template/rescuetag_spec.rb", "spec/inversion/template/subscribetag_spec.rb", "spec/inversion/template/tag_spec.rb", "spec/inversion/template/textnode_spec.rb", "spec/inversion/template/timedeltatag_spec.rb", "spec/inversion/template/unlesstag_spec.rb", "spec/inversion/template/uriencodetag_spec.rb", "spec/inversion/template/yieldtag_spec.rb", "spec/inversion/template_spec.rb", "spec/inversion/tilt_spec.rb", "spec/inversion_spec.rb"]
  s.homepage = "http://deveiate.org/projects/Inversion"
  s.licenses = ["BSD"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0")
  s.rubygems_version = "2.4.5"
  s.signing_key = "/Volumes/Keys/ged-private_gem_key.pem"
  s.summary = "Inversion is a templating system for Ruby"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<loggability>, ["~> 0.11"])
      s.add_development_dependency(%q<hoe-mercurial>, ["~> 1.4"])
      s.add_development_dependency(%q<hoe-manualgen>, ["~> 0.3.0"])
      s.add_development_dependency(%q<hoe-deveiate>, ["~> 0.6"])
      s.add_development_dependency(%q<hoe-highline>, ["~> 0.2"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<highline>, ["~> 1.6"])
      s.add_development_dependency(%q<hoe-bundler>, ["~> 1.2"])
      s.add_development_dependency(%q<rack-test>, ["~> 0.6"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.8"])
      s.add_development_dependency(%q<sinatra>, ["~> 1.4"])
      s.add_development_dependency(%q<tilt>, ["~> 2.0"])
      s.add_development_dependency(%q<sysexits>, ["~> 1.0"])
      s.add_development_dependency(%q<trollop>, ["~> 2.0"])
      s.add_development_dependency(%q<rdoc-generator-fivefish>, ["~> 0"])
      s.add_development_dependency(%q<hoe>, ["~> 3.13"])
    else
      s.add_dependency(%q<loggability>, ["~> 0.11"])
      s.add_dependency(%q<hoe-mercurial>, ["~> 1.4"])
      s.add_dependency(%q<hoe-manualgen>, ["~> 0.3.0"])
      s.add_dependency(%q<hoe-deveiate>, ["~> 0.6"])
      s.add_dependency(%q<hoe-highline>, ["~> 0.2"])
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<highline>, ["~> 1.6"])
      s.add_dependency(%q<hoe-bundler>, ["~> 1.2"])
      s.add_dependency(%q<rack-test>, ["~> 0.6"])
      s.add_dependency(%q<simplecov>, ["~> 0.8"])
      s.add_dependency(%q<sinatra>, ["~> 1.4"])
      s.add_dependency(%q<tilt>, ["~> 2.0"])
      s.add_dependency(%q<sysexits>, ["~> 1.0"])
      s.add_dependency(%q<trollop>, ["~> 2.0"])
      s.add_dependency(%q<rdoc-generator-fivefish>, ["~> 0"])
      s.add_dependency(%q<hoe>, ["~> 3.13"])
    end
  else
    s.add_dependency(%q<loggability>, ["~> 0.11"])
    s.add_dependency(%q<hoe-mercurial>, ["~> 1.4"])
    s.add_dependency(%q<hoe-manualgen>, ["~> 0.3.0"])
    s.add_dependency(%q<hoe-deveiate>, ["~> 0.6"])
    s.add_dependency(%q<hoe-highline>, ["~> 0.2"])
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<highline>, ["~> 1.6"])
    s.add_dependency(%q<hoe-bundler>, ["~> 1.2"])
    s.add_dependency(%q<rack-test>, ["~> 0.6"])
    s.add_dependency(%q<simplecov>, ["~> 0.8"])
    s.add_dependency(%q<sinatra>, ["~> 1.4"])
    s.add_dependency(%q<tilt>, ["~> 2.0"])
    s.add_dependency(%q<sysexits>, ["~> 1.0"])
    s.add_dependency(%q<trollop>, ["~> 2.0"])
    s.add_dependency(%q<rdoc-generator-fivefish>, ["~> 0"])
    s.add_dependency(%q<hoe>, ["~> 3.13"])
  end
end
