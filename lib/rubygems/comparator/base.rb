require 'rainbow'
require 'rubygems/comparator/utils'
require 'rubygems/comparator/report'

class Gem::Comparator
  class Base
    include Gem::Comparator::Utils
    include Gem::Comparator::Report::Signs

    attr_accessor :compares

    ##
    # Compare Gem::Specification objects by default
    #
    # To override create your own initialize method and
    # set expect(:packages) to expect Gem::Package objects.

    def initialize
      expect(:specs)
    end

    class DiffCommandMissing < StandardError; end

    private

      def expect(what)
        @compares = what
      end

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

  end
end
