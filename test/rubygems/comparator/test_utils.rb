require_relative '../../test_helper'
require 'rubygems/comparator'

class TestGemComparatorUtils < Minitest::Test
  def setup
    super
    # This should pull in Gem::Comparator::Utils
    @test_comparator = Class.new(Gem::Comparator::Base).new
  end

  def test_param_exist?
    params = (Gem::Comparator::Utils::SPEC_PARAMS +
              Gem::Comparator::Utils::SPEC_FILES_PARAMS +
              Gem::Comparator::Utils::DEPENDENCY_PARAMS +
              Gem::Comparator::Utils::GEMFILE_PARAMS)

    params.each do |param|
      assert_equal true, @test_comparator.send(:param_exists?, param)
    end

    assert_equal false, @test_comparator.send(:param_exists?, 'i_dont_exist')
  end

  def test_filter_params
    params = Gem::Comparator::Utils::SPEC_PARAMS
    assert_equal ['license'], @test_comparator.send(:filter_params, params, 'license')
  end

  def test_filter_for_brief_mode
    exclude = Gem::Comparator::Utils::FILTER_WHEN_BRIEF + ['not_excluded']
    assert_equal ['not_excluded'], @test_comparator.send(:filter_for_brief_mode, exclude)
  end
end
