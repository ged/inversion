# -*- encoding: utf-8 -*-
# stub: inversion 1.2.0.pre20171113183403 ruby lib

Gem::Specification.new do |s|
  s.name = "inversion".freeze
  s.version = "1.2.0.pre20171113183403"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze, "Mahlon E. Smith".freeze]
  s.date = "2017-11-14"
  s.description = "Inversion is a templating system for Ruby. It uses the \"Inversion of Control\"\nprinciple to decouple the contents and structure of templates from the code\nthat uses them, making it easier to separate concerns, keep your tests simple,\nand avoid polluting scopes with ephemeral data.".freeze
  s.email = ["ged@FaerieMUD.org".freeze, "mahlon@martini.nu".freeze]
  s.executables = ["inversion".freeze]
  s.extra_rdoc_files = ["Examples.rdoc".freeze, "GettingStarted.rdoc".freeze, "Guide.rdoc".freeze, "History.rdoc".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "Tags.rdoc".freeze, "README.rdoc".freeze, "History.rdoc".freeze]
  s.files = ["ChangeLog".freeze, "Examples.rdoc".freeze, "GettingStarted.rdoc".freeze, "Guide.rdoc".freeze, "History.rdoc".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "Rakefile".freeze, "Tags.rdoc".freeze, "bin/inversion".freeze, "lib/inversion.rb".freeze, "lib/inversion/command.rb".freeze, "lib/inversion/exceptions.rb".freeze, "lib/inversion/mixins.rb".freeze, "lib/inversion/monkeypatches.rb".freeze, "lib/inversion/parser.rb".freeze, "lib/inversion/renderstate.rb".freeze, "lib/inversion/sinatra.rb".freeze, "lib/inversion/template.rb".freeze, "lib/inversion/template/attrtag.rb".freeze, "lib/inversion/template/begintag.rb".freeze, "lib/inversion/template/calltag.rb".freeze, "lib/inversion/template/codetag.rb".freeze, "lib/inversion/template/commenttag.rb".freeze, "lib/inversion/template/configtag.rb".freeze, "lib/inversion/template/containertag.rb".freeze, "lib/inversion/template/defaulttag.rb".freeze, "lib/inversion/template/elsetag.rb".freeze, "lib/inversion/template/elsiftag.rb".freeze, "lib/inversion/template/endtag.rb".freeze, "lib/inversion/template/escapetag.rb".freeze, "lib/inversion/template/fortag.rb".freeze, "lib/inversion/template/fragmenttag.rb".freeze, "lib/inversion/template/iftag.rb".freeze, "lib/inversion/template/importtag.rb".freeze, "lib/inversion/template/includetag.rb".freeze, "lib/inversion/template/node.rb".freeze, "lib/inversion/template/pptag.rb".freeze, "lib/inversion/template/publishtag.rb".freeze, "lib/inversion/template/rescuetag.rb".freeze, "lib/inversion/template/subscribetag.rb".freeze, "lib/inversion/template/tag.rb".freeze, "lib/inversion/template/textnode.rb".freeze, "lib/inversion/template/timedeltatag.rb".freeze, "lib/inversion/template/unlesstag.rb".freeze, "lib/inversion/template/uriencodetag.rb".freeze, "lib/inversion/template/yieldtag.rb".freeze, "lib/inversion/tilt.rb".freeze, "spec/data/sinatra/hello.inversion".freeze, "spec/data/unknown-tag.tmpl".freeze, "spec/helpers.rb".freeze, "spec/inversion/mixins_spec.rb".freeze, "spec/inversion/monkeypatches_spec.rb".freeze, "spec/inversion/parser_spec.rb".freeze, "spec/inversion/renderstate_spec.rb".freeze, "spec/inversion/sinatra_spec.rb".freeze, "spec/inversion/template/attrtag_spec.rb".freeze, "spec/inversion/template/begintag_spec.rb".freeze, "spec/inversion/template/calltag_spec.rb".freeze, "spec/inversion/template/codetag_spec.rb".freeze, "spec/inversion/template/commenttag_spec.rb".freeze, "spec/inversion/template/configtag_spec.rb".freeze, "spec/inversion/template/containertag_spec.rb".freeze, "spec/inversion/template/defaulttag_spec.rb".freeze, "spec/inversion/template/elsetag_spec.rb".freeze, "spec/inversion/template/elsiftag_spec.rb".freeze, "spec/inversion/template/endtag_spec.rb".freeze, "spec/inversion/template/escapetag_spec.rb".freeze, "spec/inversion/template/fortag_spec.rb".freeze, "spec/inversion/template/fragmenttag_spec.rb".freeze, "spec/inversion/template/iftag_spec.rb".freeze, "spec/inversion/template/importtag_spec.rb".freeze, "spec/inversion/template/includetag_spec.rb".freeze, "spec/inversion/template/node_spec.rb".freeze, "spec/inversion/template/pptag_spec.rb".freeze, "spec/inversion/template/publishtag_spec.rb".freeze, "spec/inversion/template/rescuetag_spec.rb".freeze, "spec/inversion/template/subscribetag_spec.rb".freeze, "spec/inversion/template/tag_spec.rb".freeze, "spec/inversion/template/textnode_spec.rb".freeze, "spec/inversion/template/timedeltatag_spec.rb".freeze, "spec/inversion/template/unlesstag_spec.rb".freeze, "spec/inversion/template/uriencodetag_spec.rb".freeze, "spec/inversion/template/yieldtag_spec.rb".freeze, "spec/inversion/template_spec.rb".freeze, "spec/inversion/tilt_spec.rb".freeze, "spec/inversion_spec.rb".freeze]
  s.homepage = "http://deveiate.org/projects/Inversion".freeze
  s.licenses = ["BSD".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.0".freeze)
  s.rubygems_version = "2.6.13".freeze
  s.signing_key = "/Volumes/Keys and Things/ged-private_gem_key.pem".freeze
  s.summary = "Inversion is a templating system for Ruby".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<loggability>.freeze, ["~> 0.12"])
      s.add_development_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_development_dependency(%q<hoe-deveiate>.freeze, ["~> 0.9"])
      s.add_development_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_development_dependency(%q<highline>.freeze, ["~> 1.6"])
      s.add_development_dependency(%q<rack-test>.freeze, ["~> 0.6"])
      s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.8"])
      s.add_development_dependency(%q<sinatra>.freeze, ["~> 1.4"])
      s.add_development_dependency(%q<tilt>.freeze, ["~> 1.4"])
      s.add_development_dependency(%q<sysexits>.freeze, ["~> 1.0"])
      s.add_development_dependency(%q<trollop>.freeze, ["~> 2.0"])
      s.add_development_dependency(%q<rdoc>.freeze, ["~> 5.1"])
      s.add_development_dependency(%q<rdoc-generator-fivefish>.freeze, ["~> 0.3"])
      s.add_development_dependency(%q<configurability>.freeze, ["~> 3.1"])
      s.add_development_dependency(%q<rspec-wait>.freeze, ["~> 0.0"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 3.16"])
    else
      s.add_dependency(%q<loggability>.freeze, ["~> 0.12"])
      s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.9"])
      s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_dependency(%q<highline>.freeze, ["~> 1.6"])
      s.add_dependency(%q<rack-test>.freeze, ["~> 0.6"])
      s.add_dependency(%q<simplecov>.freeze, ["~> 0.8"])
      s.add_dependency(%q<sinatra>.freeze, ["~> 1.4"])
      s.add_dependency(%q<tilt>.freeze, ["~> 1.4"])
      s.add_dependency(%q<sysexits>.freeze, ["~> 1.0"])
      s.add_dependency(%q<trollop>.freeze, ["~> 2.0"])
      s.add_dependency(%q<rdoc>.freeze, ["~> 5.1"])
      s.add_dependency(%q<rdoc-generator-fivefish>.freeze, ["~> 0.3"])
      s.add_dependency(%q<configurability>.freeze, ["~> 3.1"])
      s.add_dependency(%q<rspec-wait>.freeze, ["~> 0.0"])
      s.add_dependency(%q<hoe>.freeze, ["~> 3.16"])
    end
  else
    s.add_dependency(%q<loggability>.freeze, ["~> 0.12"])
    s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
    s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.9"])
    s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
    s.add_dependency(%q<highline>.freeze, ["~> 1.6"])
    s.add_dependency(%q<rack-test>.freeze, ["~> 0.6"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.8"])
    s.add_dependency(%q<sinatra>.freeze, ["~> 1.4"])
    s.add_dependency(%q<tilt>.freeze, ["~> 1.4"])
    s.add_dependency(%q<sysexits>.freeze, ["~> 1.0"])
    s.add_dependency(%q<trollop>.freeze, ["~> 2.0"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 5.1"])
    s.add_dependency(%q<rdoc-generator-fivefish>.freeze, ["~> 0.3"])
    s.add_dependency(%q<configurability>.freeze, ["~> 3.1"])
    s.add_dependency(%q<rspec-wait>.freeze, ["~> 0.0"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.16"])
  end
end
