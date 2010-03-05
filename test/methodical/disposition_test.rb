require File.expand_path("../test_helper", File.dirname(__FILE__))
require 'methodical/disposition'

class DispositionTest < Test::Unit::TestCase
  def self.test_predicate(predicate, truth_table)
    context "##{predicate}" do
      truth_table.each_pair do |status, expected|
        specify "#{expected} when #{status.inspect}" do
          assert_equal expected, Methodical::Disposition(status, "", nil).send(predicate)
        end
      end
    end
  end

  specify "aliases memento to result" do
    it = Methodical::Disposition.new([:in_progress, "", nil])
    it.result = 42
    assert_equal 42, it.memento
    it.memento = 24
    assert_equal 24, it.result
  end
  
  test_predicate(:ok?, {
      :succeeded   => true,
      :sufficient  => true,
      :not_started => true,
      :in_progress => true,
      :finish      => true,
      :skipped     => true,
      :failed      => false,
      :bad         => false,
      :abort       => false
    })

  test_predicate(:succeeded?, {
      :succeeded   => true,
      :sufficient  => true,
      :not_started => false,
      :in_progress => false,
      :finish      => true,
      :skipped     => false,
      :failed      => false,
      :bad         => false,
      :abort       => false
    })

  test_predicate(:bad?, {
      :succeeded   => false,
      :sufficient  => false,
      :not_started => false,
      :in_progress => false,
      :finish      => false,
      :skipped     => false,
      :failed      => false,
      :bad         => true,
      :abort       => false
    })

  test_predicate(:done?, {
      :succeeded   => true,
      :sufficient  => true,
      :not_started => false,
      :in_progress => false,
      :finish      => true,
      :skipped     => true,
      :failed      => true,
      :bad         => true,
      :abort       => true
    })

  test_predicate(:skipped?, {
      :succeeded   => false,
      :sufficient  => false,
      :not_started => false,
      :in_progress => false,
      :finish      => false,
      :skipped     => true,
      :failed      => false,
      :bad         => false,
      :abort       => false
    })

  test_predicate(:continuable?, {
      :succeeded   => true,
      :sufficient  => true,
      :finish      => false,
      :not_started => true,
      :in_progress => true,
      :skipped     => true,
      :failed      => true,
      :bad         => true,
      :abort       => false
    })

  test_predicate(:decisive?, {
      :succeeded   => false,
      :sufficient  => true,
      :finish      => true,
      :not_started => false,
      :in_progress => false,
      :skipped     => false,
      :failed      => true,
      :bad         => true,
      :abort       => true
    })

  test_predicate(:done_and_ok?, {
      :succeeded   => true,
      :sufficient  => true,
      :finish      => true,
      :not_started => false,
      :in_progress => false,
      :skipped     => true,
      :failed      => false,
      :bad         => false,
      :abort       => false
    })

end

