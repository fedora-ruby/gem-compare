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
    assert_equal 'DIFFERENT license:',  @report['license'].header.data
    assert_equal 'DIFFERENT licenses:', @report['licenses'].header.data
    assert_equal '0.0.1: MIT',   @report['license'].all_messages[1].data
    assert_equal '0.0.2: GPLv2', @report['license'].all_messages[2].data
    assert_equal '0.0.3: GPLv2', @report['license'].all_messages[3].data
    assert_equal '0.0.4: GPLv2', @report['license'].all_messages[4].data
    assert_equal '0.0.1: MIT',   @report['licenses'].all_messages[1].data
    assert_equal '0.0.2: GPLv2', @report['licenses'].all_messages[2].data
    assert_equal '0.0.3: GPLv2', @report['licenses'].all_messages[3].data
    assert_equal '0.0.4: GPLv2', @report['licenses'].all_messages[4].data
  end
end
