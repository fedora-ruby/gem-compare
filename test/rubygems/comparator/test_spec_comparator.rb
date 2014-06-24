require 'rubygems/test_case'
require 'rubygems/comparator'

class TestSpecComparator < Gem::TestCase
  def setup
    super

    options = { keep_all: true, log_all: true, no_color: true }
    versions = ['0.0.1', '0.0.2', '0.0.3', '0.0.4']

    @comparator = Gem::Comparator.new(options)

    Dir.chdir(File.expand_path('../../gemfiles', File.dirname(__FILE__))) do
      @comparator.options.merge!({ output: Dir.getwd })
      @comparator.compare_versions('lorem', versions)
    end

    @report = @comparator.report
  end
  
  def test_name_comparison
    assert_equal 'SAME name', @report['name'].header.data
    assert_equal 'SAME name', @report['name'].lines(0)
  end
  
  def test_version_comparison
    assert_equal 'DIFFERENT version:',  @report['version'].header.data
    assert_equal 'DIFFERENT version:',  @report['version'].lines(0)
    assert_equal '0.0.1: 0.0.1', @report['version'].lines(1)
    assert_equal '0.0.2: 0.0.2', @report['version'].lines(2)
    assert_equal '0.0.3: 0.0.3', @report['version'].lines(3)
    assert_equal '0.0.4: 0.0.4', @report['version'].lines(4)
  end

  def test_licenses_comparison
    assert_equal 'DIFFERENT license:',  @report['license'].header.data
    assert_equal 'DIFFERENT licenses:', @report['licenses'].header.data
    assert_equal 'DIFFERENT license:',  @report['license'].lines(0)
    assert_equal 'DIFFERENT licenses:', @report['licenses'].lines(0)
    assert_equal '0.0.1: MIT',   @report['license'].lines(1)
    assert_equal '0.0.2: GPLv2', @report['license'].lines(2)
    assert_equal '0.0.3: GPLv2', @report['license'].lines(3)
    assert_equal '0.0.4: GPLv2', @report['license'].lines(4)
    assert_equal '0.0.1: ["MIT"]',   @report['licenses'].lines(1)
    assert_equal '0.0.2: ["GPLv2"]', @report['licenses'].lines(2)
    assert_equal '0.0.3: ["GPLv2"]', @report['licenses'].lines(3)
    assert_equal '0.0.4: ["GPLv2"]', @report['licenses'].lines(4)
  end
  
  def test_authors_comparison
    assert_equal 'SAME author',  @report['author'].header.data
    assert_equal 'SAME authors', @report['authors'].header.data
    assert_equal 'SAME author',  @report['author'].lines(0)
    assert_equal 'SAME authors', @report['authors'].lines(0)
  end
  
  def test_email_comparison
    assert_equal 'SAME email', @report['email'].header.data
    assert_equal 'SAME email', @report['email'].lines(0)
  end
  
  def test_summary_comparison
    assert_equal 'DIFFERENT summary:', @report['summary'].header.data
    assert_equal 'DIFFERENT summary:', @report['summary'].lines(0)
    assert_equal '0.0.1: lorem is a gem for testing gem-compare', @report['summary'].lines(1)
    assert_equal '0.0.2: lorem is a gem for testing gem-compare', @report['summary'].lines(2)
    assert_equal '0.0.3: lorem is a gem for testing gem-compare', @report['summary'].lines(3)
    assert_equal '0.0.4: lorem is a gem for testing gem-compare plugin', @report['summary'].lines(4)
  end
  
  def test_description_comparison
    assert_equal 'DIFFERENT description:', @report['description'].header.data
    assert_equal 'DIFFERENT description:', @report['description'].lines(0)
    assert_equal '0.0.1: lorem changes a lot so we can test gem-compare a lot', @report['description'].lines(1)
    assert_equal '0.0.2: lorem changes a lot so we can test gem-compare a lot', @report['description'].lines(2)
    assert_equal '0.0.3: lorem changes a lot so we can test gem-compare a lot', @report['description'].lines(3)
    assert_equal '0.0.4: lorem changes a lot so we can test gem-compare plugin a lot', @report['description'].lines(4)
  end
  
  def test_homepage_comparison
    assert_equal 'DIFFERENT homepage:', @report['homepage'].header.data
    assert_equal 'DIFFERENT homepage:', @report['homepage'].lines(0)
    assert_equal '0.0.1: ', @report['homepage'].lines(1)
    assert_equal '0.0.2: ', @report['homepage'].lines(2)
    assert_equal '0.0.3: http://lorem.lorem', @report['homepage'].lines(3)
    assert_equal '0.0.4: http://lorem.lorem', @report['homepage'].lines(4)
  end
  
  def test_platform_comparison
    assert_equal 'SAME platform', @report['platform'].header.data
    assert_equal 'SAME platform', @report['platform'].lines(0)
  end
  
  def test_require_paths_comparison
    assert_equal 'SAME require_paths', @report['require_paths'].header.data
    assert_equal 'SAME require_paths', @report['require_paths'].lines(0)
  end
  
  def test_bindir_comparison
    assert_equal 'SAME bindir', @report['bindir'].header.data
    assert_equal 'SAME bindir', @report['bindir'].lines(0)
  end
  
  def test_rubygems_version_comparison
    assert_equal 'SAME rubygems_version', @report['rubygems_version'].header.data
    assert_equal 'SAME rubygems_version', @report['rubygems_version'].lines(0)
  end
  
  def test_cert_chain_comparison
    assert_equal 'SAME cert_chain', @report['cert_chain'].header.data
    assert_equal 'SAME cert_chain', @report['cert_chain'].lines(0)
  end
  
  def test_executables_comparison
    assert_equal 'DIFFERENT executables:', @report['executables'].header.data
    assert_equal 'DIFFERENT executables:', @report['executables'].lines(0)
  end
  
  def test_extensions_comparison
    assert_equal 'SAME extensions', @report['extensions'].header.data
    assert_equal 'SAME extensions', @report['extensions'].lines(0)
  end
  
  def test_metadata_comparison
    assert_equal 'SAME metadata', @report['metadata'].header.data
    assert_equal 'SAME metadata', @report['metadata'].lines(0)
  end
  
  def test_post_install_message_comparison
    assert_equal 'SAME post_install_message', @report['post_install_message'].header.data
    assert_equal 'SAME post_install_message', @report['post_install_message'].lines(0)
  end
  
  def test_rdoc_options_comparison
    assert_equal 'SAME rdoc_options', @report['rdoc_options'].header.data
    assert_equal 'SAME rdoc_options', @report['rdoc_options'].lines(0)
  end
  
  def test_required_ruby_version_comparison
    assert_equal 'SAME required_ruby_version', @report['required_ruby_version'].header.data
    assert_equal 'SAME required_ruby_version', @report['required_ruby_version'].lines(0)
  end
  
  def test_required_rubygems_version_comparison
    assert_equal 'SAME required_rubygems_version', @report['required_rubygems_version'].header.data
    assert_equal 'SAME required_rubygems_version', @report['required_rubygems_version'].lines(0)
  end
  
  def test_requirements_comparison
    assert_equal 'SAME requirements', @report['requirements'].header.data
    assert_equal 'SAME requirements', @report['requirements'].lines(0)
  end
  
  def test_signing_key_comparison
    assert_equal 'SAME signing_key', @report['signing_key'].header.data
    assert_equal 'SAME signing_key', @report['signing_key'].lines(0)
  end
  
  def test_has_rdoc_comparison
    assert_equal 'SAME has_rdoc', @report['has_rdoc'].header.data
    assert_equal 'SAME has_rdoc', @report['has_rdoc'].lines(0)
  end
  
  def test_date_comparison
    assert_equal 'SAME date', @report['date'].header.data
    assert_equal 'SAME date', @report['date'].lines(0)
  end
  
end
