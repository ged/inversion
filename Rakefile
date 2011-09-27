#!/usr/bin/env rake

begin
	require 'hoe'
rescue LoadError
	abort "This Rakefile requires hoe (gem install hoe)"
end

Hoe.plugin :mercurial
Hoe.plugin :signing
Hoe.plugin :manualgen

Hoe.plugins.delete :rubyforge

hoespec = Hoe.spec 'inversion' do
	self.readme_file = 'README.rdoc'
	self.history_file = 'History.rdoc'
	self.extra_rdoc_files << 'README.rdoc' << 'History.rdoc'

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'
	self.developer 'Mahlon E. Smith', 'mahlon@martini.nu'

	self.dependency 'ripper',        '~> 1.0',    :development unless defined?( Encoding )
	self.dependency 'rspec',         '~> 2.6.0',  :development
	self.dependency 'tilt',          '~> 1.3.2',  :development
	self.dependency 'sinatra',       '~> 1.2.6',  :development
	self.dependency 'rack-test',     '~> 0.6.0',  :development
	self.dependency 'simplecov',     '~> 0.4.2',  :development
	self.dependency 'hoe-manualgen', '~> 0.2.0',  :development

	# bin/inversion deps
	self.dependency 'trollop',       '~> 1.16.2', :development
	self.dependency 'highline',      '~> 1.6.2',  :development
	self.dependency 'sysexits',      '~> 1.0.2',  :development

	self.spec_extras[:licenses] = ["BSD"]
	self.require_ruby_version( '>=1.9.2' )
	self.hg_sign_tags = true if self.respond_to?( :hg_sign_tags= )
	self.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

# Ensure the specs pass before checking in
task 'hg:precheckin' => :spec

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

