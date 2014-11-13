require_relative 'lib/rubygems/comparator'

Gem::Specification.new do |s|
  s.name     = 'gem-compare'
  s.version  = Gem::Comparator::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary     = 'RubyGems plugin for comparing gem versions'
  s.description = <<-EOF
                    gem-compare is a RubyGems plugin that helps to compare versions of the given gem.
                    It searches for differences in metadata as well as in files.
                  EOF
  s.homepage = 'http://github.com/strzibny/gem-compare'
  s.licenses = ['MIT']
  s.author   = 'Josef Stribny'
  s.email    = 'strzibny@strzibny.name'
  s.files = Dir['README.md', 'LICENSE', 'Rakefile',
                'lib/**/*.rb', 'lib/**/**/*.rb', 'test/**/test*.rb']
  s.required_ruby_version     = '>= 2.0.0'
  s.required_rubygems_version = '>= 2.0.0'
  s.add_runtime_dependency 'json'
  s.add_runtime_dependency 'curb'
  s.add_runtime_dependency 'diffy'
  s.add_runtime_dependency 'rainbow'
  s.add_runtime_dependency 'gemnasium-parser'
end
