# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lorem/version'

Gem::Specification.new do |spec|
  spec.name          = "lorem"
  spec.version       = Lorem::VERSION
  spec.authors       = ["Josef Stribny"]
  spec.email         = ["jstribny@redhat.com"]
  spec.summary       = "lorem is a gem for testing gem-compare"
  spec.description   = "lorem changes a lot so we can test gem-compare a lot"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = ["lorem.gemspec", "Gemfile", "Rakefile", "LICENSE.txt", "README.md"] +
                       Dir.glob("lib/**/*")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
