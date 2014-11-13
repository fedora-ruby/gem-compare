require 'rake/testtask'
require 'rdoc/task'

Rake::RDocTask.new do |rd|
  rd.main = 'README.md'
  rd.rdoc_files.include('README.md', 'lib/**/*.rb')
end

Rake::TestTask.new('test') do |t|
  t.libs << 'test'
  t.pattern = 'test/**/test*.rb'
  t.verbose = true
end

task :default => [:test]
