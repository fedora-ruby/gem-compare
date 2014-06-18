require 'rubygems/test_case'
require 'rubygems/comparator'

class TestSpecComparator < Gem::TestCase
  def setup
    super

    options = { keep_all: true, no_color: true }
    versions = ['0.0.1', '0.0.2', '0.0.3', '0.0.4']

    @comparator = Gem::Comparator.new(options)

    Dir.chdir(File.expand_path('../../gemfiles', File.dirname(__FILE__))) do
      @comparator.options.merge!({ output: Dir.getwd })
      @comparator.compare_versions('lorem', versions)
    end

    @report = @comparator.report
  end

  def test_licenses_comparison
    assert_equal @report['licenses'].header.data, 'DIFFERENT licenses:'
  end
end
