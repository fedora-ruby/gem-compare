require 'rainbow'

class Gem::Comparator
  module Utils
    include Gem::UserInteraction

    SPACE = ' '
    DEFAULT_INDENT = SPACE*7
    OPERATORS = ['=', '!=', '>', '<', '>=', '<=', '~>']
    VERSION_REGEX = /\A(\d+\.){0,}\d+(\.[a-zA-Z]+\d{0,1}){0,1}\z/
    SPEC_PARAMS = %w[ author
                      authors
                      bindir
                      cert_chain
                      date
                      description
                      email
                      executables
                      extensions
                      has_rdoc
                      homepage
                      license
                      licenses
                      metadata
                      name
                      platform
                      post_install_message
                      rdoc_options
                      require_paths
                      required_ruby_version
                      required_rubygems_version
                      requirements
                      rubygems_version
                      signing_key
                      summary
                      version ]
    SPEC_FILES_PARAMS = %w[ files
                            test_files
                            extra_rdoc_files ]
    DEPENDENCY_PARAMS = %w[ runtime_dependency
                            development_dependency ]
    GEMFILE_PARAMS = %w[ gemfiles ]

    # Duplicates or obvious changes
    FILTER_WHEN_BRIEF = %w[ author
                            date
                            license
                            platform
                            rubygems_version
                            version ]

    private

      def param_exists?(param)
        (SPEC_PARAMS.include? param) ||
        (SPEC_FILES_PARAMS.include? param) ||
        (DEPENDENCY_PARAMS.include? param) ||
        (GEMFILE_PARAMS.include? param)
      end

      def filter_params(params, param, brief_mode = false)
        if param
          if params.include? param
            return [param]
          else
            return []
          end
        end
        if brief_mode
          filter_for_brief_mode(params)
        else
          params
        end
      end

      def filter_for_brief_mode(params)
        params.delete_if{ |p| FILTER_WHEN_BRIEF.include?(p) }
      end

      ##
      # Print info only in verbose mode

      def info(msg)
        say msg if Gem.configuration.really_verbose
      end

      def warn(msg)
        say Rainbow("WARNING: #{msg}").red
      end

      def error(msg)
        say Rainbow("ERROR: #{msg}").red
        exit 1
      end
  end

  module DirUtils

    SHEBANG_REGEX = /\A#!.*/

    attr_accessor :files_first_line

    def self.file_first_line(file)
      @files_first_line[file] ||=
        File.open(file){ |f| f.readline }.gsub(/(.*)\n/, '\1')
    rescue
    end

    def self.file_has_shebang?(file)
      file_first_line(file) =~ SHEBANG_REGEX
    end

    def self.files_same_first_line?(file1, file2)
      file_first_line(file1) == file_first_line(file2)
    end

    def self.file_permissions(file)
      sprintf("%o", File.stat(file).mode)
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

  end
end
