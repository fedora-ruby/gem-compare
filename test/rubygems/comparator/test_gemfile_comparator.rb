require 'rubygems/test_case'
require 'rubygems/comparator'

class TestGemfileComparator < Gem::TestCase
  def setup
    super

    options = { keep_all: true, log_all: true, no_color: true }
    versions = ['0.0.1', '0.0.2', '0.0.3', '0.0.4']

    @comparator = Gem::Comparator.new(options)

    Dir.chdir(File.expand_path('../../gemfiles', File.dirname(__FILE__))) do
      @comparator.options.merge!({ output: Dir.getwd })
      @comparator.compare_versions('lorem', versions)
    end

    @report = @comparator.report
  end
  
  def test_gemfile_comparison
    assert_equal '0.0.1->0.0.2:', @report['gemfiles']['0.0.1->0.0.2'].header.data
    assert_equal [], @report['gemfiles']['0.0.1->0.0.2'].messages
    assert_equal [], @report['gemfiles']['0.0.2->0.0.3'].messages
    assert_equal [], @report['gemfiles']['0.0.3->0.0.4']['added'].messages
    assert_equal '* Deleted', @report['gemfiles']['0.0.3->0.0.4'].lines(1)
    assert_equal ['appraisal [">= 0"]'], @report['gemfiles']['0.0.3->0.0.4']['deleted'].lines(1)
    assert_equal ['minitest from: [">= 0"] to: ["= 5.0.0"]'], @report['gemfiles']['0.0.3->0.0.4']['updated'].lines(1)
  end
end
