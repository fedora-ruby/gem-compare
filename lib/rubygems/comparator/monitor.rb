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
      prev_file = prev_file.nil? ? Tempfile.new.path : prev_file
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

    def self.files_diff(prev_file, curr_file)
      prev_file = prev_file.nil? ? Tempfile.new.path : prev_file
      changes = ''
      Diffy::Diff.new(
        prev_file, curr_file, :source => 'files', :context => 0, :include_diff_info => true
      ).each do |line|
        case line
        when /^\+/ then changes << Rainbow(line).green
        when /^-/ then changes << Rainbow(line).red
        else changes << line
        end
      end
      changes
    end

    def self.files_permissions_changes(prev_file, curr_file, ignore_group_writable=false)
      prev_permissions = File.stat(prev_file).mode
      curr_permissions = File.stat(curr_file).mode

      diff = prev_permissions ^ curr_permissions
      diff ^= 020 if ignore_group_writable

      if diff != 0
        "  (!) New permissions: " +
        "#{format_permissions(prev_permissions)} -> #{format_permissions(curr_permissions)}"
      else
        ''
      end
    end

    def self.new_file_permissions(file, ignore_group_writable=false)
      file_permissions = File.stat(file).mode
      formatted_file_permissions = format_permissions(file_permissions)

      file_permissions ^= 020 if ignore_group_writable

      unless file_permissions == 0100644 || \
          (DirUtils.gem_bin_file?(file) && file_permissions == 0100755)
        return "  (!) Unexpected permissions: #{formatted_file_permissions}"
      end
      ''
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
        "  (!) Shebang found: #{DirUtils.file_first_line(file)}"
      else
        ''
      end
    end

    def self.format_permissions(permissions)
      sprintf("%o", permissions)
    end
  end
end
