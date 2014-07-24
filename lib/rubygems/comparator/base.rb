require 'rainbow'
require 'rubygems/comparator/utils'
require 'rubygems/comparator/report'

class Gem::Comparator
  class Base
    include Gem::Comparator::Utils
    include Gem::Comparator::Report::Signs

    class DiffCommandMissing < StandardError; end

    private

      def extract_gem(package, target_dir)
        gem_file = File.basename(package.spec.full_name, '.gem')
        gem_dir = File.join(target_dir, gem_file)

        if Dir.exist? gem_dir
          info "Unpacked gem version exists, using #{gem_dir}."
          return gem_dir
        end

        info "Unpacking gem '#{package.spec.full_name}' in " + gem_dir
        package.extract_files gem_dir
        gem_dir
      end

      def check_diff_command_is_installed
        IO.popen('diff --version')
      rescue Exception
        raise DiffCommandMissing, \
          'Calling `diff` command failed. Do you have it installed?'
      end
  end
end
