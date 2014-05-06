require 'diffy'
require 'rubygems/comparator/base'

class Gem::Comparator
  class FileListComparator
    include Gem::Comparator::Base

    ##
    # Compares file lists in spec

    def compare(packages, report, options = {})
      info 'Checking file lists...'
      check_diff_command_is_installed

      @packages = packages

      # Check file lists from older versions to newer
      filter_params(SPEC_FILES_PARAMS, options[:param]).each do |param|
        all_same = true

        packages.each_with_index do |pkg, index|
          unpacked_gem_dirs[packages[index].spec.version] = extract_gem(pkg, options[:output])
          next if index == 0

          # File lists as arrays
          previous = value_from_spec(param, packages[index-1].spec)
          current = value_from_spec(param, pkg.spec)
          next unless (previous && current)

          if previous == current && !all_same
            report[param] << "#{Rainbow(packages[index].spec.version).blue}: No change"
          end

          unless previous == current
            deleted = previous - current
            added = current - previous
            same = current - added

            if !added.empty? || !deleted.empty?
              report[param].set_header "#{FAIL} #{param}:"
              all_same = false
            end

            vers = "#{packages[index-1].spec.version}->#{packages[index].spec.version}"
            report[param][vers].set_header "#{Rainbow(packages[index-1].spec.version).blue}->#{Rainbow(packages[index].spec.version).blue}:"

            report[param][vers]['deleted'].set_header '* Deleted:'
            report[param][vers]['deleted'] << deleted unless deleted.empty?

            report[param][vers]['added'].set_header '* Added:'
            report[param][vers]['added'] << added unless added.empty?

            report[param][vers]['changed'].set_header '* Changed:'
            report = check_same_files(param, vers, index, same, report)
          end
        end

        report[param] << "#{SUCCESS} #{param}" if all_same && options[:log_all]
      end
      report
    end

    private

      def unpacked_gem_dirs
        @unpacked_gem_dirs ||= {}
      end

      def check_same_files(param, vers, index, files, report)
        files.each do |file|
          prev_file = File.join(unpacked_gem_dirs[@packages[index-1].spec.version], file)
          curr_file = File.join(unpacked_gem_dirs[@packages[index].spec.version], file)

          line_changes = lines_changed(prev_file, curr_file)

          changes = permission_changed(prev_file, curr_file),
                    executables_changed(prev_file, curr_file),
                    shebangs_changed(prev_file, curr_file)

          unless (line_changes.empty? && changes.join.empty?)
            report[param][vers]['changed'] << \
              "#{file} changed: #{line_changes}"
          end

          changes.each do |change|
            report[param][vers]['changed'] << change unless change.empty?
          end
	end
	report
      end

      def lines_changed(prev_file, curr_file)
       line = compact_files_diff(prev_file, curr_file)
       "#{Rainbow(line.count('+')).green}/#{Rainbow(line.count('-')).red}"
      end

      def value_from_spec(param, spec)
        if spec.respond_to? :"#{param}"
          spec.send(:"#{param}")
        else
          warn "#{spec.full_name} does not respond to " +
               "#{param}, skipping check"
          nil
        end
      end

      ##
      # Return changes between files
      #
      # + for line added
      # - for line deleted

      def compact_files_diff(prev_file, curr_file)
        changes = ''
        Diffy::Diff.new(
	  prev_file, curr_file, :source => 'files', :context => 0
	).each do |line|
          case line
          when /^\+/ then changes << Rainbow('+').green
          when /^-/ then changes << Rainbow('-').red
          end
        end
	changes
      end

      ##
      # Get file's permission

      def file_permissions(file)
        sprintf("%o", File.stat(file).mode)
      end

      ##
      # Find and return permission changes between files

      def permission_changed(prev_file, curr_file)
        prev_permissions = file_permissions(prev_file)
        curr_permissions = file_permissions(curr_file)

        if prev_permissions != curr_permissions
          "#{FAIL} permissions: " +
          "#{prev_permissions} -> #{curr_permissions}"
        else
          ''
        end
      end

      def executables_changed(prev_file, curr_file)
        prev_executable = File.stat(prev_file).executable?
        curr_executable = File.stat(curr_file).executable?

        if !prev_executable && curr_executable
          "#{FAIL} is now executable!"
        elsif prev_executable && !curr_executable
          "#{FAIL} is no longer executable!"
        else
          ''
        end
      end

      def first_line(file)
        begin
          File.open(file) { |f| f.readline }.gsub(/(.*)\n/, '\1')
        rescue
          info "#{file} is binary, skipping shebang check"
	  ''
        end
      end

      def shebangs_changed(prev_file, curr_file)
        first_lines = {}
        [prev_file, curr_file].each do |file|
          first_lines[file] = first_line(file)
        end

        return '' if first_lines[prev_file] == first_lines[curr_file]

        prev_has_shebang = (first_lines[prev_file] =~ SHEBANG_REGEX)
        curr_has_shebang = (first_lines[curr_file] =~ SHEBANG_REGEX)

        if prev_has_shebang && !curr_has_shebang
            "#{FAIL} shebang probably lost: #{first_lines[prev_file]}"
        elsif !prev_has_shebang && curr_has_shebang
            "#{FAIL} shebang probably added: #{first_lines[curr_file]}"
        elsif prev_has_shebang && curr_has_shebang
            "#{FAIL} shebang probably changed: " +
            "#{first_lines[prev_file]} -> #{first_lines[curr_file]}"
        else
            ''
	end
     end

  end
end
