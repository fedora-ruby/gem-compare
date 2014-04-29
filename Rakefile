require 'rubygems/package_task'
require 'rake/testtask'
require 'rdoc/task'

gemspec = Gem::Specification.new do |s|
  s.name     = "gem-compare"
  s.version  = "0.0.1"
  s.platform = Gem::Platform::RUBY
  s.summary     = "RubyGems plugin for comparing gem versions."
  s.description = <<-EOF
                    `gem-compare` is a RubyGems plugin that helps to compare versions of the given gem.
		                It searches for differences in metadata as well as in files.
                  EOF
  s.homepage = "http://github.com/strzibny/gem-compare"
  s.licenses = ["MIT"]
  s.author   = "Josef Stribny"
  s.email    = "strzibny@strzibny.name"
  s.required_ruby_version     = ">= 1.9.3"
  s.required_rubygems_version = ">= 1.8"
  s.files = FileList["README.md", "LICENSE", "Rakefile",
                     "lib/**/*.rb", "lib/**/**/*.rb", "test/**/test*.rb"]
  #TODO: add requires, diffy, rainbow
end

Gem::PackageTask.new gemspec do |pkg|
end

Rake::RDocTask.new do |rd|
  rd.main = "README.md"
  rd.rdoc_files.include("README.md", "lib/**/*.rb")
end

Rake::TestTask.new('test') do |t|
  t.libs << 'test'
  t.pattern = 'test/**/test*.rb'
  t.verbose = true
end

task :default => [:test]
