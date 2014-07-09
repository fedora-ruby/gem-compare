require 'tmpdir'
require 'rbconfig'
require 'rainbow'
require 'rubygems/package'
require 'rubygems/dependency'
require 'rubygems/spec_fetcher'
require 'rubygems/comparator/base'
require 'rubygems/comparator/report'
require 'rubygems/comparator/spec_comparator'
require 'rubygems/comparator/file_list_comparator'
require 'rubygems/comparator/dependency_comparator'
require 'rubygems/comparator/gemfile_comparator'

class Gem::Comparator
  include Gem::Comparator::Base
  attr_accessor :options, :report

  VERSION = '0.0.1'

  ##
  # Set the working dir and process options
  #
  # Creates temporal directory if the gem files shouldn't be kept

  def initialize(options)
    unless options[:keep_all]
      options[:output] = Dir.mktmpdir
    end

    if options[:param] && !param_exists?(options[:param])
      error 'Invalid parameter.'
    end

    if options[:no_color]
      Rainbow.enabled = false
    end

    @options = options

    # Results from the comparison
    @report = Gem::Comparator::Report.new
  end

  ##
  # Compare versions
  #
  # Compares file lists, requirements, other meta data

  def compare_versions(gem_name, versions)
    info "gem-compare in #{VERSION}"
    # Expand versions (<=, >=, ~>) and sort them
    versions = expand_versions(gem_name, versions)

    error 'Only one version specified. Specify at lease two versions.' \
      if versions.size == 1

    versions.each do |version|
      download_gems? ? download_package(gem_name, version) : download_specification(gem_name, version)
    end

    @report.set_header "Compared versions: #{versions}"

    comparators = [SpecComparator,
                   FileListComparator,
                   DependencyComparator,
                   GemfileComparator]

    comparators.each do |c|
      comparator = c.new
      cmp = (c::COMPARES == :packages) ? gem_packages.values : gem_specs.values
      @report = comparator.compare(cmp, @report, @options)
    end

    # Clean up
    FileUtils.rm_rf options[:output] unless options[:keep_all]
  end

  def print_results
    info 'Printing results...'
    @report.print
  end

  private

    def expand_versions(gem_name, versions)
      info 'Expanding versions...'
      expanded = []
      versions.each do |version|
        if version =~ VERSION_REGEX
          expanded << version
          next
        end
        op, v = (version.scan /(>=|<=|~>|!=|>|<|=)\s*(.*)/).flatten
        # Supported operator and version?
        if OPERATORS.include?(op) && v =~ VERSION_REGEX
          dep = Gem::Dependency.new gem_name, version
          specs_and_sources, errors = Gem::SpecFetcher.fetcher.spec_for_dependency dep
          specs_and_sources.each do |s|
            expanded << s[0].version
          end
        else
          warn "Unsupported version specification: #{version}, skipping."
        end
      end

      versions = expanded.uniq.map do |v|
        Gem::Version.new v
      end.sort.map(&:to_s)

      error 'No versions found.' if versions.size == 0

      info "Versions: #{versions}"
      versions
    end

    def gem_file_name(gem_name, version)
     "#{gem_name}-#{version}.gem"
    end

    def download_package(gem_name, version)
      gem_file = gem_file_name(gem_name, version)
      return gem_packages["#{gem_file}"] if gem_packages["#{gem_file}"]

      find_downloaded_gem(gem_file)
      return gem_packages["#{gem_file}"] if gem_packages["#{gem_file}"]

      spec, source = download_specification(gem_name, version)

      Dir.chdir @options[:output] do
        source.download spec
      end

      package = Gem::Package.new File.join(@options[:output], gem_file)
      use_package(package)
      info "#{gem_file} downloaded."

      package
    end

    def download_specification(gem_name, version)
      gem_file = gem_file_name(gem_name, version)
      return gem_specs["#{gem_file}"] if gem_specs["#{gem_file}"]

      find_downloaded_gem(gem_file)
      return gem_specs["#{gem_file}"] if gem_specs["#{gem_file}"]

      dep = Gem::Dependency.new gem_name, version
      specs_and_sources, errors = Gem::SpecFetcher.fetcher.spec_for_dependency dep
      spec, source = specs_and_sources.max_by { |s,| s.version }
      error "Gem #{gem_name} in #{version} doesn't exist." if spec.nil?
      gem_specs["#{gem_file}"] = spec

      [spec, source]
    end

    def find_downloaded_gem(gem_file)
      if File.exists? File.join(@options[:output], gem_file)
        info "#{gem_file} exists, using already downloaded file."
        package = Gem::Package.new File.join(@options[:output], gem_file)
        use_package(package)
        [package, package.spec]
      else
        [nil, nil]
      end
    end

    def use_package(package)
      gem_file = gem_file_name(package.spec.name, package.spec.version)
      gem_packages["#{gem_file}"] = package
      gem_specs["#{gem_file}"] = package.spec
    end

    def download_gems?
      @options[:param] ? SPEC_FILES_PARAMS.include?(@options[:param]) : true
    end

    def gem_packages
      @gem_packages ||= {}
    end

    def gem_specs
      @gem_specs ||= {}
    end

end
