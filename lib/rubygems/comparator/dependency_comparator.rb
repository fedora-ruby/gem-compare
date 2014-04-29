require 'rubygems/comparator/base'

class Gem::Comparator
  class DependencyComparator
    include Gem::Comparator::Base

    ##
    # Compares dependencies in spec

    def compare(packages, report, options = {})
      info 'Checking dependencies...'

      dependency_params(options[:param]).each do |type|
        cat = "#{type}_dependency".to_s
        report[cat].set_header "[ #{FAIL} ] #{type} dependencies differ:"
        packages.each_with_index do |pkg, index|
          next if index == 0

          prev_dependencies = packages[index-1].spec.dependencies.keep_if { |d| d.type == type }
          curr_dependencies = packages[index].spec.dependencies.keep_if { |d| d.type == type }

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

          ver = "#{packages[index-1].spec.version}->#{packages[index].spec.version}"

          report[cat][ver].section do
            set_header "#{Rainbow(packages[index-1].spec.version).blue}->#{Rainbow(pkg.spec.version).blue}: "

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
      end
      report
    end

    private

      def dependency_params(param)
        if param
          if DEPENDENCY_PARAMS.include? param.to_sym
            return [param.to_sym]
          else
            return []
          end
        end

        DEPENDENCY_PARAMS
      end

  end
end
