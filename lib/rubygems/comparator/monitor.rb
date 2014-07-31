require 'diffy'
require 'rubygems/comparator/base'
require 'rubygems/comparator/dir_utils'

class Gem::Comparator
  module Monitor

    def self.lines_changed(prev_file, curr_file)
      line = compact_files_diff(prev_file, curr_file)
      return '' if line.empty?
      plus = "+#{line.count('+')}"
      minus = "-#{line.count('-')}"
      "#{Rainbow(plus).green}/#{Rainbow(minus).red}"
    end

    def self.compact_files_diff(prev_file, curr_file)
      changes = ''
      Diffy::Diff.new(
        prev_file, curr_file, :source => 'files', :context => 0
      ).each do |line|
        case line
        when /^\+/ then changes << Rainbow('+').green
        when /^-/ then changes << Rainbow('-').red
        end
      end
      changes
    end

    def self.files_permissions_changes(prev_file, curr_file)
      prev_permissions = DirUtils.file_permissions(prev_file)
      curr_permissions = DirUtils.file_permissions(curr_file)

      if prev_permissions != curr_permissions
        "  (!) New permissions: " +
        "#{prev_permissions} -> #{curr_permissions}"
      else
        ''
      end
    end

    def self.new_file_permissions(file)
      file_permissions = DirUtils.file_permissions(file)

      if file_permissions != '100644'
        unless (DirUtils.gem_bin_file?(file) && file_permissions == '100755')
          "  (!) Unexpected permissions: #{file_permissions}"
        end
      else
        ''
      end
    end

    def self.files_executability_changes(prev_file, curr_file)
      prev_executable = File.stat(prev_file).executable?
      curr_executable = File.stat(curr_file).executable?

      if !prev_executable && curr_executable
        "  (!) File is now executable!"
      elsif prev_executable && !curr_executable
        "  (!) File is no longer executable!"
      else
        ''
      end
    end

    def self.new_file_executability(file)
      file_executable = File.stat(file).executable?

      if file_executable && !DirUtils.gem_bin_file?(file)
        "  (!) File is executable"
      elsif !file_executable && DirUtils.gem_bin_file?(file)
        "  (!) File is not executable"
      else
        ''
      end
    end

    def self.files_shebang_changes(prev_file, curr_file)
      return '' if DirUtils.files_same_first_line?(prev_file, curr_file)

      prev_has_shebang = DirUtils.file_has_shebang? prev_file
      curr_has_shebang = DirUtils.file_has_shebang? curr_file

      if prev_has_shebang && !curr_has_shebang
          "  (!) Shebang probably lost: #{DirUtils.file_first_line(prev_file)}"
      elsif !prev_has_shebang && curr_has_shebang
          "  (!) Shebang probably added: #{DirUtils.file_first_line(curr_file)}"
      elsif prev_has_shebang && curr_has_shebang
          "  (!) Shebang probably changed: " +
          "#{first_lines[prev_file]} -> #{DirUtils.file_first_line(curr_file)}"
      else
          ''
      end
    end

    def self.new_file_shebang(file)
      file_has_shebang = DirUtils.file_has_shebang? file

      if file_has_shebang
        " (!) Shebang found: #{DirUtils.file_first_line(file)}"
      else
        ''
      end
    end
  end
end
