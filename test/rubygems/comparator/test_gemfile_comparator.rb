require 'test_helper'

class TestGemfileComparator < TestGemComparator

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
