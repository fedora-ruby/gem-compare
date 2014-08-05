require 'test_helper'

class TestFileListComparator < TestGemComparator

  def test_files_comparison
    assert_equal 'DIFFERENT files:', @report['files'].header.data
    assert_equal '0.0.1->0.0.2:', @report['files'].lines(1)
    assert_equal "CHANGELOG.md", @report['files']['0.0.1->0.0.2']['added'].lines(1)
    assert_equal [], @report['files']['0.0.1->0.0.2']['deleted'].messages
    assert_equal [], @report['files']['0.0.1->0.0.2']['updated'].messages
    assert_equal "bin/lorem", @report['files']['0.0.2->0.0.3']['added'].lines(1)
    assert_equal "(!) Unexpected permissions: 100664", @report['files']['0.0.2->0.0.3']['added'].lines(2).strip
    assert_equal "(!) File is not executable", @report['files']['0.0.2->0.0.3']['added'].lines(3).strip
    assert_equal "(!) Shebang found: #!/usr/bin/ruby", @report['files']['0.0.2->0.0.3']['added'].lines(4).strip
    assert_equal [], @report['files']['0.0.2->0.0.3']['deleted'].messages
    assert_equal [], @report['files']['0.0.2->0.0.3']['updated'].messages
    assert_equal [], @report['files']['0.0.3->0.0.4']['added'].messages
    assert_equal [], @report['files']['0.0.3->0.0.4']['deleted'].messages
    assert_equal [], @report['files']['0.0.3->0.0.4']['updated'].messages
  end

  def test_test_files_comparison
    assert_equal 'SAME test_files:', @report['test_files'].header.data
  end
end
