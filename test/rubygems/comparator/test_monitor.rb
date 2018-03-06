require 'test_helper'

class TestMonitor < TestGemModule

  def test_lines_changed
    file1 = File.join(@v001, 'lib/lorem.rb')
    file2 = File.join(@v002, 'lib/lorem.rb')
    assert_equal '+4/-0', Gem::Comparator::Monitor.lines_changed(file1, file2)
  end

  def test_compact_files_diff
    file1 = File.join(@v001, 'lib/lorem.rb')
    file2 = File.join(@v002, 'lib/lorem.rb')
    assert_equal '++++', Gem::Comparator::Monitor.compact_files_diff(file1, file2)
  end

  def test_files_permissions_changes
    file1 = File.join(@v003, 'bin/lorem')
    file2 = File.join(@v004, 'bin/lorem')
    assert_equal '(!) New permissions: 100664 -> 100775', Gem::Comparator::Monitor.files_permissions_changes(file1, file2).strip 
  end

  def test_files_permissions_changes_ignores_group_writable_added
    file1 = Tempfile.new
    file2 = Tempfile.new
    begin
      File.chmod(0644, file1)
      File.chmod(0664, file2)
      assert_equal '', Gem::Comparator::Monitor.files_permissions_changes(file1.path, file2.path, true)
    ensure
      file1.unlink
      file2.unlink
    end
  end

  def test_files_permissions_changes_ignores_group_writable_other_changes
    file1 = Tempfile.new
    file2 = Tempfile.new
    begin
      File.chmod(0644, file1)
      File.chmod(0660, file2)
      assert_equal '  (!) New permissions: 100644 -> 100660', Gem::Comparator::Monitor.files_permissions_changes(file1.path, file2.path, true)
    ensure
      file1.unlink
      file2.unlink
    end
  end

  def test_files_permissions_changes_ignores_group_writable_removed
    file1 = Tempfile.new
    file2 = Tempfile.new
    begin
      File.chmod(0664, file1)
      File.chmod(0644, file2)
      assert_equal '', Gem::Comparator::Monitor.files_permissions_changes(file1.path, file2.path, true)
    ensure
      file1.unlink
      file2.unlink
    end
  end

  def test_new_file_permissions
    file1 = File.join(@v004, 'bin/lorem')
    file2 = File.join(@v004, 'lib/lorem.rb')
    assert_equal '(!) Unexpected permissions: 100775', Gem::Comparator::Monitor.new_file_permissions(file1).strip 
    assert_equal '(!) Unexpected permissions: 100664', Gem::Comparator::Monitor.new_file_permissions(file2).strip 
  end

  def test_new_file_permissions_ignore_group_writable
    file = Tempfile.new
    begin
      File.chmod(0664, file)
      assert_equal '', Gem::Comparator::Monitor.new_file_permissions(file, true)
    ensure
      file.unlink
    end
  end

  def test_new_file_permissions_ignore_group_writable_unreadable
    file = Tempfile.new
    begin
      File.chmod(0660, file)
      assert_equal '  (!) Unexpected permissions: 100660', Gem::Comparator::Monitor.new_file_permissions(file, true)
    ensure
      file.unlink
    end
  end

  def test_files_executability_changes
    file1 = File.join(@v003, 'bin/lorem')
    file2 = File.join(@v004, 'bin/lorem')
    assert_equal '(!) File is now executable!', Gem::Comparator::Monitor.files_executability_changes(file1, file2).strip
  end

  def test_new_file_executability
    file1 = File.join(@v003, 'bin/lorem')
    file2 = File.join(@v004, 'bin/lorem')
    assert_equal '(!) File is not executable', Gem::Comparator::Monitor.new_file_executability(file1).strip
    assert_equal '', Gem::Comparator::Monitor.new_file_executability(file2).strip
  end

  def test_files_shebang_changes
    file1 = File.join(@v003, 'bin/lorem')
    file2 = File.join(@v004, 'bin/lorem')
    assert_equal '', Gem::Comparator::Monitor.files_shebang_changes(file1, file2).strip
  end

  def test_new_file_shebang
    file1 = File.join(@v003, 'bin/lorem')
    assert_equal '(!) Shebang found: #!/usr/bin/ruby', Gem::Comparator::Monitor.new_file_shebang(file1).strip
  end
end
