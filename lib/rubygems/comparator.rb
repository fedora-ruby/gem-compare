#####
# TODO:
# - compare Gemfiles in detail
# - specs from rubygems json api
#   https://api.rubygems.org/quick/Marshal.4.8/json-1.5.5-java.gemspec.rz
# - packagers brief mode
#####

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

class Gem::Comparator
  include Gem::Comparator::Base
  attr_accessor :options, :report

  ##
  # Set the working dir and process options
  #
  # Creates temporal directory if the gem files shouldn't be kept

  def initialize(options)
    unless options[:keep_all]
      options[:output] = Dir.mktmpdir
    end

    if options[:param]
      unless ((SPEC_PARAMS.include? options[:param]) ||
              (SPEC_FILES_PARAMS.include? options[:param]) ||
              (DEPENDENCY_PARAMS.include? "#{options[:param]}".to_sym))
        warn('Invalid parameter.')
        exit 1
      end
    end

    if options[:no_color]
      Rainbow.enabled = false
    end

    @options = options
    @output = {}

    # Results from the comparison
    @report = Gem::Comparator::Report.new
  end

  ##
  # Compare versions
  #
  # Compares file lists, requirements, other meta data

  def compare_versions(gem_name, versions)
    packages = []

    # Expand versions (<=, >=, ~>) and sort them
    versions = expand_versions(gem_name, versions)
    if versions.size == 1
      warn 'Only one version specified, no version to compare to. Specify at lease two versions.'
      exit 1
    end

    versions.each do |version|
      pkg = download_gem(gem_name, version)
      packages << pkg
    end

    [SpecComparator, FileListComparator, DependencyComparator].each do |c|
      comparator = c.new
      @report = comparator.compare(packages, @report, @options)
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
        op, v = (version.scan /(>=|<=|~>)(.*)/).flatten

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
      expanded.uniq.map{ |v| Gem::Version.new v }.sort.map(&:to_s)
    end

    def gem_file_name(gem_name, version)
     "#{gem_name}-#{version}.gem"
    end

    def download_gem(gem_name, version)
      gem_file = gem_file_name(gem_name, version)

      # Cache
      if File.exists? File.join(@options[:output], gem_file)
        info "#{gem_file} exists, using already downloaded file."

        package = Gem::Package.new File.join(@options[:output], gem_file)
        return package
      end

      dep = Gem::Dependency.new gem_name, version
      specs_and_sources, errors = Gem::SpecFetcher.fetcher.spec_for_dependency dep
      spec, source = specs_and_sources.max_by { |s,| s.version }

      raise "Gem #{gem_name} in #{version} doesn't exist." if spec.nil?

      Dir.chdir @options[:output] do
        source.download spec
      end

      package = Gem::Package.new File.join(@options[:output], gem_file)
      puts "#{gem_file} downloaded."

      package
    end

    def download_gems?
      options[:param] && SPEC_FILES_PARAMS.include?(options[:param])
    end

end
