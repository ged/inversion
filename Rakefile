#!/usr/bin/env rake

require 'rake/clean'
require 'rdoc/task'

begin
	require 'hoe'
rescue LoadError
	abort "This Rakefile requires hoe (gem install hoe)"
end

GEMSPEC = 'inversion.gemspec'

Hoe.plugin :mercurial
Hoe.plugin :signing
Hoe.plugin :manualgen
Hoe.plugin :bundler

Hoe.plugins.delete :rubyforge

hoespec = Hoe.spec 'inversion' do
	self.readme_file = 'README.rdoc'
	self.history_file = 'History.rdoc'
	self.extra_rdoc_files << 'README.rdoc' << 'History.rdoc'
	self.license "BSD"

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'
	self.developer 'Mahlon E. Smith', 'mahlon@martini.nu'

	self.dependency 'loggability',   '~> 0.11'

	self.dependency 'highline',      '~> 1.6', :development
	self.dependency 'hoe-deveiate',  '~> 0.5', :development
	self.dependency 'hoe-bundler',   '~> 1.2', :development
	self.dependency 'rack-test',     '~> 0.6', :development
	self.dependency 'simplecov',     '~> 0.8', :development
	self.dependency 'sinatra',       '~> 1.4', :development
	self.dependency 'tilt',          '~> 2.0', :development
	self.dependency 'sysexits',      '~> 1.0', :development
	self.dependency 'trollop',       '~> 2.0', :development
	self.dependency 'rdoc-generator-fivefish', '~> 0', :development

	self.require_ruby_version( '>=2.0.0' )
	self.hg_sign_tags = true if self.respond_to?( :hg_sign_tags= )
	self.check_history_on_release = true if self.respond_to?( :check_history_on_release= )
	self.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

# Ensure the specs pass before checking in
task 'hg:precheckin' => [:check_history, 'bundler:gemfile', :check_manifest, :spec]

if Rake::Task.task_defined?( '.gemtest' )
	Rake::Task['.gemtest'].clear
	task '.gemtest' do
		$stderr.puts "Not including a .gemtest until I'm confident the test suite is idempotent."
	end
end

desc "Build a coverage report"
task :coverage do
	ENV["COVERAGE"] = 'yes'
	Rake::Task[:spec].invoke
end


# Use the fivefish formatter for docs generated from development checkout
if File.directory?( '.hg' )
	require 'rdoc/task'

	Rake::Task[ 'docs' ].clear
	RDoc::Task.new( 'docs' ) do |rdoc|
	rdoc.main = "README.rdoc"
	rdoc.rdoc_files.include( "*.rdoc", "ChangeLog", "lib/**/*.rb" )
	rdoc.generator = :fivefish
	rdoc.rdoc_dir = 'doc'
	end
end

task :gemspec => GEMSPEC
file GEMSPEC => __FILE__
task GEMSPEC do |task|
	spec = $hoespec.spec
	spec.files.delete( '.gemtest' )
	spec.version = "#{spec.version}.pre#{Time.now.strftime("%Y%m%d%H%M%S")}"
	File.open( task.name, 'w' ) do |fh|
		fh.write( spec.to_ruby )
	end
end

CLOBBER.include( GEMSPEC.to_s )
task :default => :gemspec
