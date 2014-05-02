require 'rainbow'

class Gem::Comparator
  module Base
    include Gem::UserInteraction

    class DiffCommandMissing < StandardError; end

    SPACE = ' '
    DEFAULT_INDENT = SPACE*7
    OPERATORS = ['=', '!=', '>', '<', '>=', '<=', '~>']
    VERSION_REGEX = /\A(\d+\.){0,}\d+(\.[a-zA-Z]+\d{0,1}){0,1}\z/
    SHEBANG_REGEX = /\A#!.*/
    FAIL = Rainbow('DIFFERENT').red.bright
    SUCCESS = Rainbow('SAME').green.bright
    SPEC_PARAMS = %w[ author authors name platform require_paths rubygems_version summary
                      license licenses  bindir cert_chain description email executables
                      extensions homepage metadata post_install_message rdoc_options
                      required_ruby_version required_rubygems_version requirements
                      signing_key has_rdoc date version ].sort
    SPEC_FILES_PARAMS = %w[ files test_files extra_rdoc_files ]
    DEPENDENCY_PARAMS = %w[ runtime_dependency development_dependency ]

    private

      def param_exists?(param)
        (SPEC_PARAMS.include? param) ||
        (SPEC_FILES_PARAMS.include? param) ||
        (DEPENDENCY_PARAMS.include? param)
      end

      def filter_params(params, param)
        if param
          if params.include? param
            return [param]
          else
            return []
          end
        end

        params
      end

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

      def extract_gem(package, target_dir)
        gem_file = File.basename(package.spec.full_name, '.gem')
        gem_dir = File.join(target_dir, gem_file)

        if Dir.exists? gem_dir
          info "Unpacked gem version exists, using #{gem_dir}."
          return gem_dir
        end

        info "Unpacking gem '#{package.spec.full_name}' in " + gem_dir
        package.extract_files gem_dir
        gem_dir
      end

      def check_diff_command_is_installed
        begin
          IO.popen('diff --version')
        rescue Exception
          raise DiffCommandMissing, \
            'Calling `diff` command failed. Do you have it installed?'
        end
      end
  end
end
