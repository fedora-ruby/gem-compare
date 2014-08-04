require 'rubygems/test_case'
require 'rubygems/comparator'

class TestGemComparatorReport < Gem::TestCase
  def setup
    super
    @report = Gem::Comparator::Report.new
    @report['1'] << '1'
    @report['1']['2'] << '2'
    @report['1']['unused'].set_header 'Unused'
    @report['1.1'].section do
      nest('1.1.1').section do
        puts [3, 3]
      end
      puts []
    end
  end

  def test_all_messages
    assert_equal 2, @report['1'].all_messages.size
    assert_equal 1, @report['1.1'].all_messages.size
  end
end
