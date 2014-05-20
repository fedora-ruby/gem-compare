require 'gemnasium/parser'
require 'rubygems/comparator/base'

class Gem::Comparator
  class GemfileComparator
    include Gem::Comparator::Base

    COMPARES = :packages

    ##
    # Compares Gemfiles

    def compare(packages, report, options = {})
      info 'Checking Gemfiles for dependencies...'

      @packages = packages

      # Check Gemfiles from older versions to newer
      all_same = true
      report['gemfiles'].set_header "#{FAIL} Gemfile dependencies"

      packages.each_with_index do |pkg, index|
        unpacked_gem_dirs[@packages[index].spec.version] = extract_gem(pkg, options[:output])
        next if index == 0

        prev_gemfile = File.join(unpacked_gem_dirs[@packages[index-1].spec.version], 'Gemfile')
        curr_gemfile = File.join(unpacked_gem_dirs[@packages[index].spec.version], 'Gemfile')

        vers = "#{@packages[index-1].spec.version}->#{@packages[index].spec.version}"
        report['gemfiles'][vers].set_header "#{Rainbow(packages[index-1].spec.version).blue}->" +
                                            "#{Rainbow(packages[index].spec.version).blue}:"

        if File.exists?(prev_gemfile) && File.exists?(curr_gemfile)
          added, deleted, updated = compare_gemfiles(prev_gemfile, curr_gemfile)

          report['gemfiles'][vers]['added'].section do
            set_header '* added:'
            puts added.map { |x| "#{x.name} #{x.requirements_list}" }  unless added.empty?
          end
          report['gemfiles'][vers]['deleted'].section do
            set_header '* deleted'
            puts deleted.map { |x| "#{x.name} #{x.requirements_list}" }  unless deleted.empty?
          end
          report['gemfiles'][vers]['updated'].section do
            set_header '* updated'
            puts updated  unless updated.empty?
          end

          all_same = false if !added.empty? || deleted.empty?

        elsif File.exists?(prev_gemfile)
          report['gemfiles'][vers] << "Gemfile removed"
          all_same = false
        elsif File.exists?(curr_gemfile)
          report['gemfiles'][vers] << "Gemfile added"
          all_same = false
        end
      end

      if all_same
        report['gemfiles'].set_header "#{SUCCESS} Gemfiles"
      end

      report
    end

    private

      def unpacked_gem_dirs
        @unpacked_gem_dirs ||= {}
      end

      def compare_gemfiles(prev_gemfile, curr_gemfile)
        prev_deps = gemfile_deps(prev_gemfile)
        curr_deps = gemfile_deps(curr_gemfile)
        added = curr_deps - prev_deps
        deleted = prev_deps - curr_deps

        split_dependencies(added, deleted)
      end

      def gemfile_deps(gemfile)
        parse_gemfile(gemfile).dependencies
      end

      def parse_gemfile(gemfile)
        Gemnasium::Parser.gemfile File.open(gemfile).read
      end

      def split_dependencies(added, deleted)
        # Find updated dependencies
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
