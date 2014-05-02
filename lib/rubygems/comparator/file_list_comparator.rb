require 'diffy'
require 'rubygems/comparator/base'

class Gem::Comparator
  class FileListComparator
    include Gem::Comparator::Base

    ##
    # Compares file lists in spec

    def compare(packages, report, options = {})
      check_diff_command_is_installed

      unpacked_gem_dirs = {}

      # Check file lists from older versions to newer
      filter_params(SPEC_FILES_PARAMS, options[:param]).each do |param|
        all_same = true

        packages.each_with_index do |pkg, index|
          unpacked_gem_dirs[packages[index].spec.version] = extract_gem(pkg, options[:output])
          next if index == 0

          # File lists as arrays
          previous, current = [], []

          if packages[index-1].spec.respond_to? :"#{param}"
            previous = packages[index-1].spec.send(:"#{param}")
          else
            warn "#{packages[index-1].spec.full_name} does not respond to #{param}, skipping check"
            next
          end

          if pkg.spec.respond_to? :"#{param}"
            current = pkg.spec.send(:"#{param}")
          else
            warn "#{pkg.spec.full_name} does not respond to #{param}, skipping check"
            next
          end

          if previous == current && !all_same
            report[param] << "#{Rainbow(packages[index].spec.version).blue}: No change"
          end

          unless previous == current
            deleted = previous - current
            added = current - previous
            same = current - added

            if !added.empty? || !deleted.empty?
              report[param].set_header "[ #{FAIL} ] #{param} differ:"
              all_same = false
            end

            vers = "#{packages[index-1].spec.version}->#{packages[index].spec.version}"
            report[param][vers].set_header "#{Rainbow(packages[index-1].spec.version).blue}->#{Rainbow(packages[index].spec.version).blue}:"

            report[param][vers]['deleted'].set_header '* Deleted:'
            report[param][vers]['deleted'] << deleted unless deleted.empty?

            report[param][vers]['added'].set_header '* Added:'
            report[param][vers]['added'] << added unless added.empty?

            report[param][vers]['changed'].set_header '* Changed:'

            same.each do |file|
              prev_file = File.join(unpacked_gem_dirs[packages[index-1].spec.version], file)
              curr_file = File.join(unpacked_gem_dirs[packages[index].spec.version], file)

              line_changes, permissions_changes, executable_changes, shebangs_changes = '', '', '', ''

              # Lines changed
              Diffy::Diff.new(prev_file, curr_file, :source => 'files', :context => 0).each do |line|
                case line
                when /^\+/ then line_changes << Rainbow('+').green
                when /^-/ then line_changes << Rainbow('-').red
                end
              end

              # Check permissions
              prev_permissions = sprintf("%o", File.stat(prev_file).mode)
              curr_permissions = sprintf("%o", File.stat(curr_file).mode)

              if prev_permissions != curr_permissions
                permissions_changes << "#{FAIL} permissions changed: #{prev_permissions} -> #{curr_permissions}"
              end

              # Check executables
              prev_executable = File.stat(prev_file).executable?
              curr_executable = File.stat(curr_file).executable?

              if !prev_executable && curr_executable
                executable_changes << "#{FAIL} is now executable!"
              elsif prev_executable && !curr_executable
                executable_changes << "#{FAIL} is no longer executable!"
              end

              # Check shebangs
              fl = {} # save first lines
              [prev_file, curr_file].each do |file|
                begin
                  fl[file.to_s] = File.open(file) { |f| f.readline }.gsub(/(.*)\n/, '\1')
                rescue
                  info "#{file} is binary, skipping shebang check."
                ensure
                  fl[file.to_s] = ''
                end
              end

              unless fl[:prev_file] == fl[:curr_file]
                prev_has_shebang = (fl[:prev_file] =~ SHEBANG_REGEX)
                curr_has_shebang = (fl[:curr_file] =~ SHEBANG_REGEX)

                if prev_has_shebang && !curr_has_shebang
                  shebangs_changes << "#{FAIL} shebang probably lost: #{pfl}"
                elsif !prev_has_shebang && curr_has_shebang
                  shebangs_changes << "#{FAIL} shebang probably added: #{cfl}"
                elsif prev_has_shebang && curr_has_shebang
                  shebangs_changes << "#{FAIL} shebang probably changed: #{pfl} -> #{cfl}"
                end
              end

              if !line_changes.empty? || !permissions_changes.empty? || !executable_changes || !shebangs_changes
                report[param][vers]['changed'] << "#{file} changed: #{Rainbow(line_changes.count('+')).green}/#{Rainbow(line_changes.count('-')).red}"
              end

              [permissions_changes, executable_changes, shebangs_changes].each do |changes|
                unless changes.empty?
                  report[param][vers]['changed'] << changes
                end
              end
            end
          end
        end

        report[param] << "[ #{SUCCESS} ] #{param} is the same" if all_same && options[:log_all]
      end
      report
    end

  end
end
