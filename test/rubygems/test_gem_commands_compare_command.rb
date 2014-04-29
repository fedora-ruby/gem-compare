require 'rubygems/test_case'
require 'rubygems/commands/compare_command'

class TestGemCommandsCompareCommand < Gem::TestCase
  def setup
    super

    @command = Gem::Commands::CompareCommand.new
  end

  def test_execute_no_gemfile
    @command.options[:args] = []

    e = assert_raises Gem::CommandLineError do
      use_ui @ui do
        @command.execute
      end
    end

    assert_match 'Please specify a gem (e.g. gem compare foo VERSION [VERSION ...])', e.message
  end

  def test_execute_no_patch
    @command.options[:args] = ['my_gem']

    e = assert_raises Gem::CommandLineError do
      use_ui @ui do
        @command.execute
      end
    end

    assert_match 'Please specify versions you want to compare (e.g. gem compare foo 0.1.0 0.2.0)', e.message
  end
end
