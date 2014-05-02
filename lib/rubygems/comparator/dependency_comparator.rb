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

          prev_dependencies = specs[index-1].dependencies.keep_if { |d| d.type == type }
          curr_dependencies = specs[index].dependencies.keep_if { |d| d.type == type }

          added = curr_dependencies - prev_dependencies
          deleted = prev_dependencies - curr_dependencies
          updated = []

          # Find updated dependencies
          added.dup.each do |a_dep|
            deleted.dup.each do |d_dep|
              if a_dep.name == d_dep.name
                unless a_dep.requirements_list == d_dep.requirements_list
                  updated << "#{a_dep.name} from: #{d_dep.requirements_list} to: #{a_dep.requirements_list}"
                end
                added.delete a_dep
                deleted.delete d_dep
              end
            end
          end

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

  end
end
