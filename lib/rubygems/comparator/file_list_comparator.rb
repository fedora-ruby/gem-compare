require 'diffy'
require 'rubygems/comparator/base'

class Gem::Comparator

  ##
  # Gem::Comparator::FileListComparator can
  # compare file lists from gem's specs
  # based on the given Gem::Package objects
  #
  # To compare the files it needs to extract
  # gem packages to +options[:output]+

  class FileListComparator < Gem::Comparator::Base
    COMPARES = :packages

    ##
    # Compare file lists for gem's Gem::Package objects
    # in +packages+ and writes the changes to the +report+
    #
    # If +options[:param]+ is set, it compares only
    # that file list

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

          vers = "#{packages[index-1].spec.version}->#{packages[index].spec.version}"

          deleted = previous - current
          added = current - previous
          same = current - added

          report[param].set_header "#{different} #{param}:"

          report[param][vers].section do
            set_header "#{Rainbow(packages[index-1].spec.version).blue}->" +
                       "#{Rainbow(packages[index].spec.version).blue}:"
            nest('deleted').section do
              set_header '* Deleted:'
              puts deleted unless deleted.empty?
            end

            nest('added').section do
              set_header '* Added:'
              puts added unless added.empty?
            end
          end
          report[param][vers]['changed'].set_header '* Changed:'
          report = check_same_files(param, vers, index, same, report)
          same_files = report[param][vers]['changed'].messages.empty?
          all_same = false unless same_files

          if previous == current && same_files && !all_same
            report[param][vers] << "#{Rainbow(packages[index-1].spec.version).blue}->" + \
                                   "#{Rainbow(packages[index].spec.version).blue}: No change"
          end

        end

        if all_same && options[:log_all]
          report[param].set_header "#{same} #{param}:"
          value = value_from_spec(param, @packages[0].spec)
          value = '[]' if value.empty?
          report[param] << value
        end
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

      def check_same_files(param, vers, index, files, report)
        files.each do |file|
          prev_file = File.join(unpacked_gem_dirs[@packages[index-1].spec.version], file)
          curr_file = File.join(unpacked_gem_dirs[@packages[index].spec.version], file)

          next unless check_files([prev_file, curr_file])

          line_changes = lines_changed(prev_file, curr_file)

          changes = permission_changed(prev_file, curr_file),
                    executables_changed(prev_file, curr_file),
                    shebangs_changed(prev_file, curr_file)

          unless (line_changes.empty? && changes.join.empty?)
            report[param][vers]['changed'] << \
              "#{file} #{line_changes}"
          end

          changes.each do |change|
            report[param][vers]['changed'] << change unless change.empty?
          end
        end
        report
      end

      ##
      # Check that files exist

      def check_files(files)
        files.each do |file|
          unless File.exist? file
            warn "#{file} mentioned in spec does not exist " +
                 "in the gem package, skipping check"
            return false
          end
        end
        true
      end


      ##
      # Return how many lines differ between +prev_file+
      # and +curr_file+ in format +ADDED/-DELETED

      def lines_changed(prev_file, curr_file)
        line = compact_files_diff(prev_file, curr_file)
        return '' if line.empty?
        "#{Rainbow(line.count('+')).green}/#{Rainbow(line.count('-')).red}"
      end

      ##
      # Return +value+ in the given +spec+

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
      # Return changes between files:
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
          "  (!) New permissions: " +
          "#{prev_permissions} -> #{curr_permissions}"
        else
          ''
        end
      end

      ##
      # Find if the file is now/or was executable

      def executables_changed(prev_file, curr_file)
        prev_executable = File.stat(prev_file).executable?
        curr_executable = File.stat(curr_file).executable?

        if !prev_executable && curr_executable
          "  (!) File is now executable!"
        elsif prev_executable && !curr_executable
          "  (!) File is no longer executable!"
        else
          ''
        end
      end

      ##
      # Return the first line of the +file+

      def first_line(file)
        begin
          File.open(file) { |f| f.readline }.gsub(/(.*)\n/, '\1')
        rescue
          info "#{file} is binary, skipping shebang check"
          ''
        end
      end

      ##
      # Find if the shabang of the file has been changed

      def shebangs_changed(prev_file, curr_file)
        first_lines = {}

        [prev_file, curr_file].each do |file|
          first_lines[file] = first_line(file)
        end

        return '' if first_lines[prev_file] == first_lines[curr_file]

        prev_has_shebang = (first_lines[prev_file] =~ SHEBANG_REGEX)
        curr_has_shebang = (first_lines[curr_file] =~ SHEBANG_REGEX)

        if prev_has_shebang && !curr_has_shebang
            "  (!) Shebang probably lost: #{first_lines[prev_file]}"
        elsif !prev_has_shebang && curr_has_shebang
            "  (!) Shebang probably added: #{first_lines[curr_file]}"
        elsif prev_has_shebang && curr_has_shebang
            "  (!) Shebang probably changed: " +
            "#{first_lines[prev_file]} -> #{first_lines[curr_file]}"
        else
            ''
        end
     end

  end
end
