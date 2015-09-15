require 'gemnasium/parser'
require 'rubygems/comparator/base'

class Gem::Comparator

  ##
  # Gem::Comparator::GemfileComparator can
  # compare dependencies between gem's Gemfiles
  # based on the given Gem::Package objects
  #
  # To compare Gemfiles it needs to extract
  # gem packages to +options[:output]+

  class GemfileComparator < Gem::Comparator::Base

    def initialize
      expect(:packages)
    end

    ##
    # Compare Gemfiles using gem's +packages+
    # and write the changes to the +report+

    def compare(packages, report, options = {})
      info 'Checking Gemfiles for dependencies...'
      return report if options[:param] && options[:param] != 'gemfiles'

      @packages = packages
      all_same = true

      # Check Gemfiles from older versions to newer
      packages.each_with_index do |pkg, index|
        unpacked_gem_dirs[@packages[index].spec.version] = extract_gem(pkg, options[:output])
        next if index == 0

        prev_gemfile = File.join(unpacked_gem_dirs[@packages[index-1].spec.version], 'Gemfile')
        curr_gemfile = File.join(unpacked_gem_dirs[@packages[index].spec.version], 'Gemfile')

        vers = "#{@packages[index-1].spec.version}->#{@packages[index].spec.version}"
        report['gemfiles'][vers].set_header "#{Rainbow(packages[index-1].spec.version).cyan}->" +
                                            "#{Rainbow(packages[index].spec.version).cyan}:"

        added, deleted, updated = compare_gemfiles(prev_gemfile, curr_gemfile)

        report['gemfiles'][vers]['added'].section do
          set_header '* Added:'
          puts added.map { |x| "#{x.name} #{x.requirements_list} (#{x.type})" } unless added.empty?
        end
        report['gemfiles'][vers]['deleted'].section do
          set_header '* Deleted'
          puts deleted.map { |x| "#{x.name} #{x.requirements_list} (#{x.type})" } unless deleted.empty?
        end
        report['gemfiles'][vers]['updated'].section do
          set_header '* Updated'
          puts updated  unless updated.empty?
        end
        all_same = false if !added.empty? || !deleted.empty?
      end
      if all_same && options[:log_all]
        report['gemfiles'].set_header "#{same} Gemfiles:"
        gemfile = File.join(unpacked_gem_dirs[@packages[1].spec.version], 'Gemfile')
        if File.exist? gemfile
          deps = gemfile_deps(gemfile)
          deps = '[]' if deps.empty?
          report['gemfiles'] << deps
        else
          report['gemfiles'] << 'No Gemfiles'
        end
      elsif !all_same
        report['gemfiles'].set_header "#{different} Gemfile dependencies"
      end

      report
    end

    private

      ##
      # Access @unpacked_gem_dirs hash that stores
      # paths to the unpacked gem dirs
      #
      # Keys of the hash are gem's versions

      def unpacked_gem_dirs
        @unpacked_gem_dirs ||= {}
      end

      ##
      # Compare two Gemfiles for dependencies
      #
      # Return [added, deleted, updated] deps

      def compare_gemfiles(prev_gemfile, curr_gemfile)
        prev_deps = gemfile_deps(prev_gemfile)
        curr_deps = gemfile_deps(curr_gemfile)
        added = curr_deps - prev_deps
        deleted = prev_deps - curr_deps

        split_dependencies(added, deleted)
      end

      ##
      # Get the Gemfile dependencies from +gemfile+

      def gemfile_deps(gemfile)
        if File.exist?(gemfile)
          parse_gemfile(gemfile).dependencies
        else
          []
        end
      end

      ##
      # Parse +gemfile+ using Gemnasium::Parser
      #
      # Return Gemnasium::Parser::Gemfile

      def parse_gemfile(gemfile)
        Gemnasium::Parser.gemfile File.open(gemfile).read
      end

      ##
      # Find updated dependencies between +added+ and
      # +deleted+ deps and move them out to +updated+.
      #
      # Return [added, deleted, updated] deps

      def split_dependencies(added, deleted)
        updated = []
        added.dup.each do |ad|
          deleted.dup.each do |dd|
            if ad.name == dd.name && ad.type == dd.type
              unless ad.requirements_list == dd.requirements_list
                updated << "#{ad.name} " +
                           "from: #{dd.requirements_list} " +
                           "to: #{ad.requirements_list}"
              end
              added.delete ad
              deleted.delete dd
            end
          end
        end
        [added, deleted, updated]
      end

  end
end
