require File.expand_path("../test_helper", File.dirname(__FILE__))
require 'methodical/dsl'
require 'methodical/action_item'

class DslTest < Test::Unit::TestCase
  include Methodical::DSL

  context "#action" do
    specify "constructs an ActionItem" do
      step = action("TITLE") do
        "RESULT"
      end

      assert_kind_of Methodical::ActionItem, step
      assert_equal "TITLE", step.title
      assert_equal "RESULT", step.execute!.result
    end
  end

  context "#sufficient" do
    specify "makes successful actions sufficient" do
      step = action("TITLE") do "RESULT" end
      sufficient_step = sufficient << step

      assert_equal :sufficient, sufficient_step.execute!.status
    end

    specify "has no effect on unsuccessful actions" do
      step = action("TITLE") do raise "FAIL" end
      sufficient_step = sufficient << step

      assert_equal :failed, sufficient_step.execute!.status
    end
  end

  context "#requisite" do
    specify "makes failed actions abort" do
      step = action("TITLE") do raise "FAIL" end
      requisite_step = requisite << step

      disposition = requisite_step.execute!
      assert_equal :abort, disposition.status
    end
  end

  context "#ignore" do
    specify "makes steps ignorable" do
      step = action("TITLE") do raise "FAIL" end
      ignored_step = ignore << step
      ignored_step.execute!
      assert ignored_step.ignored?
    end
  end

  context "#skip_if" do
    specify "skips step if condition is true" do
      step = skip_if(""){true} << action("TITLE") do 
        flunk("Should not get here") 
      end
      assert_equal :skipped, step.execute!().status
    end

    specify "performs step if condition is false" do
      sensor = :unset
      step = skip_if(""){false} << action("TITLE") do 
        "RESULT"
      end
      assert_equal "RESULT", step.execute!.result
    end

    specify "passes baton into condition" do
      baton  = stub("Baton")
      sensor = :unset
      step = skip_if(""){|b, s| sensor = b} << action("TITLE") do 
        "RESULT"
      end
      step.execute!(baton)
      assert_same baton, sensor
    end

    specify "passes step into condition" do
      baton  = stub("Baton")
      sensor = :unset
      step = skip_if(""){|b, s| sensor = s} << inner = action("TITLE") do 
        "RESULT"
      end
      step.execute!(baton)
      assert_same inner, sensor
    end

    specify "returns reason if skipped" do
      step = skip_if("EXPL"){true} << action("TITLE") do 
        flunk("Should not get here") 
      end
      assert_equal "EXPL", step.execute!().explanation
    end

    specify "updates status of step" do
      step = skip_if("EXPL"){true} << action("TITLE") do 
        flunk("Should not get here") 
      end
      step.execute!
      assert_equal "EXPL", step.explanation
      assert_equal :skipped, step.status
    end
  end

  context "#handle_error" do
    specify "rescues errors" do
      step = handle_error(RuntimeError){|b,s,e| s.succeed! } << 
        action("TITLE") do 
        raise "UH-OH"
      end
      assert_nothing_raised do
        step.execute!(nil, true)
      end
    end

    specify "substitutes its own disposition" do
      step = handle_error(RuntimeError){|b,s,e| s.succeed! } << 
        action("TITLE") do 
        raise "UH-OH"
      end
      assert_equal :succeeded, step.execute!(nil, true).status
    end

  end

  context "#filter" do
    specify "modifies step disposition" do
      step = filter {|d|
        d.merge(:status => :failed, :explanation => "MODIFIED")
      } << action("TITLE") {
        |b,s| s.succeed!("ORIGINAL")
      }
      result = step.execute!
      assert_equal :failed, result.status
      assert_equal "MODIFIED", result.explanation
      assert_equal :failed, step.status
      assert_equal "MODIFIED", step.explanation
    end
  end

  context "#recover_failure" do
    specify "executes block on failure" do
      sensor = :unset
      step = action("test") do |b,s| s.fail!("FAIL") end
      wrapped_step = recover_failure do |baton, step, disposition|
        sensor = :set
      end << step
      wrapped_step.execute!
      assert_equal :set, sensor
    end

    specify "does not execute block on success" do
      sensor = :unset
      step = action("test") do |b,s| s.succeed!("OK") end
      wrapped_step = recover_failure do |baton, step, disposition|
        sensor = :set
      end << step
      wrapped_step.execute!
      assert_equal :unset, sensor
    end

    specify "does not execute block on error" do
      sensor = :unset
      step = action("test") do raise StandardError, "BAD" end
      wrapped_step = recover_failure do |baton, step, disposition|
        sensor = :set
      end << step
      wrapped_step.execute!
      assert_equal :unset, sensor
    end
  end

  context "#retry_on_failure" do
    specify "retries on failure" do
      call_count = 0
      step = action("test") do
        call_count += 1
        if call_count == 1
          raise RuntimeError, "FAIL!"
        end
      end
      wrapped_step = (retry_on_failure(2) << step)
      wrapped_step.execute!
      assert_equal 2, call_count
    end

    specify "will not retry more than the specified number of times" do
      call_count = 0
      step = action("test") do
        call_count += 1
        raise RuntimeError, "FAIL!"
      end
      wrapped_step = (retry_on_failure(2) << step)
      wrapped_step.execute!
      assert_equal 3, call_count
    end

    specify "will not retry if timeout expires" do
      time  = Time.mktime(1970, 1, 1)
      clock = stub("Clock", :now => time)
      call_count = 0
      step = action("test") do
        call_count += 1
        time += 1
        clock.stubs(:now => time)
        raise RuntimeError, "FAIL!"
      end
      wrapped_step = (retry_on_failure(2, 1, :clock => clock) << step)
      wrapped_step.execute!
      assert_equal 1, call_count
    end
  end
  
end
