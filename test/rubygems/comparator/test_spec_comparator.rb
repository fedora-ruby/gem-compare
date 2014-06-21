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
    assert_equal 'DIFFERENT license:',  @report['license'].lines[0]
    assert_equal 'DIFFERENT licenses:', @report['licenses'].lines[0]
    assert_equal '0.0.1: MIT',   @report['license'].lines[1]
    assert_equal '0.0.2: GPLv2', @report['license'].lines[2]
    assert_equal '0.0.3: GPLv2', @report['license'].lines[3]
    assert_equal '0.0.4: GPLv2', @report['license'].lines[4]
    assert_equal '0.0.1: MIT',   @report['licenses'].lines[1]
    assert_equal '0.0.2: GPLv2', @report['licenses'].lines[2]
    assert_equal '0.0.3: GPLv2', @report['licenses'].lines[3]
    assert_equal '0.0.4: GPLv2', @report['licenses'].lines[4]
  end
  
  def test_authors_comparison
    assert_equal 'SAME author:',  @report['author'].header.data
    assert_equal 'SAME authors:', @report['authors'].header.data
    assert_equal 'SAME author:',  @report['author'].lines[0]
    assert_equal 'SAME authors:', @report['authors'].lines[0]
  end
  
  def test_name_comparison
    assert_equal 'SAME name:',  @report['author'].header.data
    assert_equal 'SAME name:', @report['authors'].lines[0]
  end
end
