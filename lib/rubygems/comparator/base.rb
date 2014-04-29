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
    FAIL = Rainbow('!!').red.bright
    SUCCESS = Rainbow('OK').green.bright
    SPEC_PARAMS = %w[ author authors name platform require_paths rubygems_version summary
                      license licenses  bindir cert_chain description email executables
                      extensions homepage metadata post_install_message rdoc_options
                      required_ruby_version required_rubygems_version requirements
                      signing_key has_rdoc date version ].sort
    SPEC_FILES_PARAMS = %w[ files test_files extra_rdoc_files ]
    DEPENDENCY_PARAMS = [ :runtime, :development ]

    private

      def warn(msg)
        say Rainbow("WARNING: #{msg}").red
      end

      def info(msg)
        say msg if Gem.configuration.really_verbose
      end

      def check_diff_command_is_installed
        begin
          IO.popen('diff --version')
        rescue Exception
          raise DiffCommandMissing, 'Calling `diff` command failed. Do you have it installed?'
        end
      end
  end
end
