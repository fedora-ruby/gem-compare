require 'minitest/autorun'
require 'rubygems/comparator'

class TestGemComparator < Minitest::Test
  def setup
    super

    options = { keep_all: true, log_all: true, no_color: true, brief_mode: false }
    versions = ['0.0.1', '0.0.2', '0.0.3', '0.0.4']

    @comparator = Gem::Comparator.new(options)

    Dir.chdir(File.expand_path('gemfiles', File.dirname(__FILE__))) do
      @comparator.options.merge!({ output: Dir.getwd })
      @comparator.compare_versions('lorem', versions)
    end

    @report = @comparator.report
  end
end

class TestGemModule < Minitest::Test
  def setup
    super
    gemfiles_path = File.expand_path('gemfiles', File.dirname(__FILE__))
    @v001 = File.join(gemfiles_path, 'lorem-0.0.1')
    @v002 = File.join(gemfiles_path, 'lorem-0.0.2')
    @v003 = File.join(gemfiles_path, 'lorem-0.0.3')
    @v004 = File.join(gemfiles_path, 'lorem-0.0.4')
  end
end
