require 'test_helper'

class TestDirUtils < TestGemModule

  def test_file_first_line
    file1 = File.join(@v001, 'lib/lorem.rb')
    file2 = File.join(@v002, 'bin/lorem')
    file3 = File.join(@v003, 'bin/lorem')
    assert_equal 'require "lorem/version"', Gem::Comparator::DirUtils.file_first_line(file1)
    assert_equal nil, Gem::Comparator::DirUtils.file_first_line(file2)
    assert_equal '#!/usr/bin/ruby', Gem::Comparator::DirUtils.file_first_line(file3)
  end

  def test_file_has_shebang?
    file1 = File.join(@v003, 'lib/lorem.rb')
    file2 = File.join(@v004, 'bin/lorem')
    assert_equal nil, Gem::Comparator::DirUtils.file_has_shebang?(file1)
    assert_equal 0, Gem::Comparator::DirUtils.file_has_shebang?(file2)
  end

  def test_files_same_first_line?
    file1 = File.join(@v001, 'lib/lorem.rb')
    file2 = File.join(@v002, 'lib/lorem.rb')
    file3 = File.join(@v003, 'bin/lorem')
    assert_equal true, Gem::Comparator::DirUtils.files_same_first_line?(file1, file2)
    assert_equal false, Gem::Comparator::DirUtils.files_same_first_line?(file1, file3)
  end

  def test_gem_bin_file
    file1 = File.join(@v001, 'lib/lorem.rb')
    file2 = File.join(@v004, 'bin/lorem')
    assert_equal nil, Gem::Comparator::DirUtils.gem_bin_file?(file1)
    assert_equal 0, Gem::Comparator::DirUtils.gem_bin_file?(file2)
  end

  def test_dirs_of_files
    files = ['Rakefile', '/dir1/file1', '/dir2/file2']
    assert_equal ["Rakefile", "/dir1/", "/dir2/"], Gem::Comparator::DirUtils.dirs_of_files(files)
  end

  def test_remove_subdirs
    dirs = ['/dir1/dir2/dir3', '/dir1/dir2', '/dir', 'Gemfile']
    assert_equal ["/dir1/dir2", "/dir", "Gemfile"], Gem::Comparator::DirUtils.remove_subdirs(dirs) 
  end
end
