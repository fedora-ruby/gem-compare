require 'pathname'

class Gem::Comparator
  module DirUtils
    SHEBANG_REGEX = /\A#!.*/

    attr_accessor :files_first_line

    def self.file_first_line(file)
      File.open(file){ |f| f.readline }.gsub(/(.*)\n/, '\1')
    rescue
    end

    def self.file_has_shebang?(file)
      file_first_line(file) =~ SHEBANG_REGEX
    end

    def self.files_same_first_line?(file1, file2)
      file_first_line(file1) == file_first_line(file2)
    end

    def self.gem_bin_file?(file)
      file =~ /(\A|.*\/)bin\/.*/
    end

    ##
    # Returns a unique list of directories and top level files
    # out of an array of files

    def self.dirs_of_files(file_list)
      dirs_of_files = []
      file_list.each do |file|
        unless Pathname.new(file).dirname.to_s == '.'
          dirs_of_files << "#{Pathname.new(file).dirname.to_s}/"
        else
          dirs_of_files << file
        end
      end
      dirs_of_files.uniq
    end

    def self.remove_subdirs(dirs)
      dirs.dup.sort_by(&:length).reverse.each do |dir|
        dirs.delete_if{ |d| d =~ /#{dir}\/.+/ }
      end
      dirs
    end
  end
end
