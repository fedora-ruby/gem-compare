require 'diffy'
require 'rubygems/comparator/base'
require 'rubygems/comparator/dir_utils'
require 'rubygems/comparator/monitor'

class Gem::Comparator

  ##
  # Gem::Comparator::FileListComparator can
  # compare file lists from gem's specs
  # based on the given Gem::Package objects
  #
  # To compare the files it needs to extract
  # gem packages to +options[:output]+

  class FileListComparator < Gem::Comparator::Base

    def initialize
      expect(:packages)

      # We need diff
      begin
        IO.popen('diff --version')
      rescue Exception
        error('Calling `diff` command failed. Do you have it installed?')
      end
    end

    ##
    # Compare file lists for gem's Gem::Package objects
    # in +packages+ and writes the changes to the +report+
    #
    # If +options[:param]+ is set, it compares only
    # that file list

    def compare(packages, report, options = {})
      info 'Checking file lists...'

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

          if options[:brief]
            deleted, dirs_added = dir_changed(previous, current)
          end

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
              puts dirs_added if options[:brief]
            end
          end
          # Add information about permissions, shebangs etc.
          report = check_added_files(param, vers, index, added, report, options[:brief])

          report[param][vers]['changed'].set_header '* Changed:'
          report = check_same_files(param, vers, index, same, report, options[:brief])
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

      ##
      # This returns [deleted, added] directories between
      # +previous+ and +current+ file lists
      #
      # For top level (.) it compares files themselves

      def dir_changed(previous, current)
        prev_dirs = DirUtils.dirs_of_files(previous)
        curr_dirs = DirUtils.dirs_of_files(current)
        deleted = DirUtils.remove_subdirs(prev_dirs - curr_dirs)
        added = DirUtils.remove_subdirs(curr_dirs - prev_dirs)
        [deleted, added]
      end

      def check_added_files(param, vers, index, files, report, brief_mode)
        files.each do |file|
          added_file = File.join(unpacked_gem_dirs[@packages[index].spec.version], file)

          #line_changes = lines_changed(prev_file, curr_file)

          changes = Monitor.new_file_permissions(added_file),
                    Monitor.new_file_executability(added_file),
                    Monitor.new_file_shebang(added_file)

          if(!changes.join.empty? || !brief_mode)
            report[param][vers]['added'] << "#{file}"
          end

          changes.each do |change|
            report[param][vers]['added'] << change unless change.empty?
          end
        end
        report
      end

      def check_same_files(param, vers, index, files, report, brief_mode)
        files.each do |file|
          prev_file = File.join(unpacked_gem_dirs[@packages[index-1].spec.version], file)
          curr_file = File.join(unpacked_gem_dirs[@packages[index].spec.version], file)

          next unless check_files([prev_file, curr_file])

          line_changes = Monitor.lines_changed(prev_file, curr_file)

          changes = Monitor.files_permissions_changes(prev_file, curr_file),
                    Monitor.files_executability_changes(prev_file, curr_file),
                    Monitor.files_shebang_changes(prev_file, curr_file)

          if(!changes.join.empty? || (!brief_mode && !line_changes.empty?))
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

  end
end
