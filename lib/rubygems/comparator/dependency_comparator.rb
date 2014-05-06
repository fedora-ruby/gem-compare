require 'rubygems/comparator/base'

class Gem::Comparator
  class DependencyComparator
    include Gem::Comparator::Base

    ##
    # Compares dependencies in spec

    def compare(specs, report, options = {})
      info 'Checking dependencies...'

      filter_params(DEPENDENCY_PARAMS, options[:param]).each do |param|
        all_same = true
        type = param.gsub('_dependency', '').to_sym

        specs.each_with_index do |s, index|
          next if index == 0

          prev_deps = specs[index-1].dependencies.keep_if { |d| d.type == type }
          curr_deps = specs[index].dependencies.keep_if { |d| d.type == type }
          added, deleted, updated = resolve_dependencies(prev_deps, curr_deps)

          if (!deleted.empty? || !added.empty? || !updated.empty?)
            all_same = false
          end

          ver = "#{specs[index-1].version}->#{specs[index].version}"

          report[param][ver].section do
            set_header "#{Rainbow(specs[index-1].version).blue}->#{Rainbow(s.version).blue}: "

            nest('deleted').section do
              set_header '* Deleted:'
              puts deleted.map { |x| "#{x.name} #{x.requirements_list}" } unless deleted.empty?
            end

            nest('added').section do
              set_header '* Added:'
              puts added.map { |x| "#{x.name} #{x.requirements_list}" } unless added.empty?
            end

            nest('updated').section do
              set_header '* Updated:'
              puts updated unless updated.empty?
            end
          end
        end
        if all_same
          report[param] << "#{SUCCESS} #{type} dependencies" if options[:log_all]
        else
          report[param].set_header "#{FAIL} #{type} dependencies:"
        end
      end
      report
    end

    private

      def resolve_dependencies(prev_deps, curr_deps)
        added = curr_deps - prev_deps
        deleted = prev_deps - curr_deps
        split_dependencies(added, deleted)
      end

      def split_dependencies(added, deleted)
        # Find updated dependencies
        updated = []
        added.dup.each do |ad|
          deleted.dup.each do |dd|
            if ad.name == dd.name
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
