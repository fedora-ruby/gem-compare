require 'tmpdir'
require 'rbconfig'
require 'rainbow'
require 'curb'
require 'json'
require 'rubygems/package'
require 'rubygems/dependency'
require 'rubygems/spec_fetcher'
require 'rubygems/comparator/version'
require 'rubygems/comparator/utils'
require 'rubygems/comparator/report'
require 'rubygems/comparator/spec_comparator'
require 'rubygems/comparator/file_list_comparator'
require 'rubygems/comparator/dependency_comparator'
require 'rubygems/comparator/gemfile_comparator'

##
# Gem::Comparator compares different version of the given
# gem. It can compare spec values as well as file lists or
# Gemfiles

class Gem::Comparator
  include Gem::Comparator::Utils
  attr_accessor :options, :report

  ##
  # Set the working dir and process options
  #
  # Creates temporal directory if the gem files shouldn't be kept

  def initialize(options)
    info "gem-compare in #{VERSION}"

    unless options[:keep_all]
      options[:output] = Dir.mktmpdir
    end

    if options[:param] && !param_exists?(options[:param])
      error 'Invalid parameter.'
    end

    if options[:no_color]
      Rainbow.enabled = false
    end

    # Let's override platforms with the latest one if
    # a platform has been specified via --platform
    if options[:added_platform]
      Gem.platforms = [Gem.platforms.last]
      options[:platform] = Gem.platforms.last.to_s
      info "Overriding platform to: #{options[:platform]}"
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
    # Expand versions (<=, >=, ~>) and sort them
    compared_versions = expand_versions(gem_name, versions)

    if versions.include?('_') && (compared_versions.size == 1)
      error 'Latest upstream version matches the version given. Nothing to compare.'
    elsif versions.include?('_') && (compared_versions.size == (versions.size - 1))
      warn 'Latest upstream version matches one of the versions given.'
    elsif compared_versions.size == 1
      error 'Only one version specified. Specify at lease two versions.'
    end

    # This should match the final versions that has been compared
    @compared_versions = compared_versions

    compared_versions.each do |version|
      download_gems? ?
        get_package(gem_name, version) :
        get_specification(gem_name, version)
    end

    @report.set_header "Compared versions: #{@compared_versions}"

    comparators = [SpecComparator,
                   FileListComparator,
                   DependencyComparator,
                   GemfileComparator]

    comparators.each do |c|
      comparator = c.new
      cmp = (comparator.compares == :packages) ? gem_packages.values : gem_specs.values
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

    ##
    # If there is an unexpanded version in +versions+ such
    # as '>= 4.0.0' or '~>1.0.0', find all existing
    # +gem_name+ versions that match the criteria
    #
    # Return list of expanded versions

    def expand_versions(gem_name, versions)
      info "Expanding versions #{versions}..."
      expanded = []
      versions.each do |version|
        version = latest_gem_version(gem_name) if version == '_'
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

      info "Expanded versions: #{versions}"
      versions
    end

    def remote_gem_versions(gem_name)
      client = Curl::Easy.new
      client.url = "https://rubygems.org/api/v1/versions/#{gem_name}.json"
      client.follow_location = true
      client.http_get
      json = JSON.parse(client.body_str)
      gems = json.collect { |version| version['number'] }
      info "Upstream versions: #{gems}"
      gems
    # "This rubygem could not be found."
    rescue JSON::ParserError
      error "Gem #{gem_name} does not exist."
      exit 1
    end

    def latest_gem_version(gem_name)
      remote_gem_versions(gem_name).map{ |v| Gem::Version.new v }.max.to_s
    end

    def gem_file_name(gem_name, version)
      if @options[:platform]
        "#{gem_name}-#{version}-#{@options[:platform]}.gem"
      else
        "#{gem_name}-#{version}.gem"
      end
    end

    def get_package(gem_name, version)
      gem_file = gem_file_name(gem_name, version)
      return gem_packages["#{gem_file}"] if gem_packages["#{gem_file}"]

      find_downloaded_gem(gem_file)
      return gem_packages["#{gem_file}"] if gem_packages["#{gem_file}"]

      download_package(gem_name, version)
    end

    def download_package(gem_name, version)
      spec, source = get_specification(gem_name, version)
      gem_file = gem_file_name(gem_name, spec.version.to_s)

      Dir.chdir @options[:output] do
        source.download spec
      end

      package = Gem::Package.new File.join(@options[:output], gem_file)
      use_package(package)
      info "#{gem_file} downloaded."

      package
    end

    def get_specification(gem_name, version)
      gem_file = gem_file_name(gem_name, version)
      return gem_specs["#{gem_file}"] if gem_specs["#{gem_file}"]

      find_downloaded_gem(gem_file)
      return gem_specs["#{gem_file}"] if gem_specs["#{gem_file}"]

      download_specification(gem_name, version)
    end

    def download_specification(gem_name, version)
      dep = Gem::Dependency.new gem_name, version
      specs_and_sources, _errors = Gem::SpecFetcher.fetcher.spec_for_dependency dep
      spec, source = specs_and_sources.max_by { |s,| s.version }
      error "Gem #{gem_name} in #{version} doesn't exist." if spec.nil?

      fix_comparing_version(version, spec.version.to_s)
      gem_file = gem_file_name(gem_name, spec.version.to_s)

      gem_specs["#{gem_file}"] = spec

      [spec, source]
    end

    ##
    # Ensure the right version is referenced

    def fix_comparing_version(version, spec_version)
      if spec_version != version
        @compared_versions.each do |v|
          if v == version
            @compared_versions[@compared_versions.index(version)] = spec_version
            return
          end
        end
      end
    end

    def find_downloaded_gem(gem_file)
      if File.exist? File.join(@options[:output], gem_file)
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
      return true if @options[:keep_all]
      @options[:param] ? !param_available_in_marshal?(@options[:param]) : true
    end

    def gem_packages
      @gem_packages ||= {}
    end

    def gem_specs
      @gem_specs ||= {}
    end

end
