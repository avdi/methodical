require File.expand_path("../test_helper", File.dirname(__FILE__))
require 'methodical/simple_action_item'

class SimpleActionItemTest < Test::Unit::TestCase
  include Methodical

  specify "can be updated all at once" do
    it = SimpleActionItem.new("Test") {}
    it.update!(:skipped, "EXPLANATION", [1,2,3])
    assert_equal :skipped, it.status
    assert_equal "EXPLANATION", it.explanation
    assert_equal [1,2,3], it.result
  end

  context "#update" do
    specify "returns a disposition" do
      it = SimpleActionItem.new("Test") {}
      assert_equal(
        Disposition.new([:skipped, "EXPLANATION", [1,2,3]]),
        it.update!(:skipped, "EXPLANATION", [1,2,3]))
    end
  end

  specify "defaults to NOT ignored" do
    it = SimpleActionItem.new("Test") {}
    assert !it.ignored?
  end

  specify "defaults to being relevant" do
    it = SimpleActionItem.new("Test") {}
    assert it.relevant?
  end

  specify "defaults to empty details" do
    it = SimpleActionItem.new("Test") {}
    assert_equal "", it.details
  end

  context "created from a block" do
    specify "executes the block when called" do
      sensor = :unset
      it = SimpleActionItem.new("Test") do
        sensor = :set
      end
      it.execute!
      assert_equal :set, sensor
    end

    specify "has the given title" do
      it = SimpleActionItem.new("Foo") {}
      assert_equal "Foo", it.title
    end

    specify "knows it is undone before being called" do
      it = SimpleActionItem.new("Foo") {}
      assert !it.done?
    end

    specify "knows it is done after being called" do
      it = SimpleActionItem.new("Foo") {}
      it.execute!
      assert it.done?
    end

    specify "has a status of :succeeded after being called" do
      it = SimpleActionItem.new("Foo") {}
      it.execute!
      assert_equal :succeeded, it.status
    end

    specify "has a status of :not_started before being called" do
      it = SimpleActionItem.new("Foo") {}
      assert_equal :not_started, it.status
    end

    specify "knows it has neither succeeded or failed before being called" do
      it = SimpleActionItem.new("Foo") {}
      assert !it.succeeded?
      assert !it.failed?
      assert !it.bad?
    end

    specify "can format a status message" do
      it = SimpleActionItem.new("Foo") {}
      assert_equal "Foo: Not started.", it.synopsis
    end

    specify "passes self to block" do
      sensor = :unset
      it = SimpleActionItem.new("Foo") do |baton, step|
        sensor = step
      end
      it.execute!(nil)
      assert_same it, sensor
    end

    specify "called with a baton object, passes baton to block" do
      sensor = :unset
      it = SimpleActionItem.new("Foo") do |baton, step|
        sensor = baton
      end
      test_baton = stub("Baton")
      it.execute!(test_baton)
      assert_same test_baton, sensor
    end
  end

  context "created from a callable" do
    specify "executes the callable when called" do
      sensor = :unset
      callable = lambda do |baton, step|
        sensor = :set
      end
      it = SimpleActionItem.new("Test", callable)
      it.execute!
      assert_equal :set, sensor
    end

    specify "called with a baton object, passes baton to callable" do
      sensor = :unset
      callable = lambda do |baton, step|
        sensor = baton
      end
      it = SimpleActionItem.new("Foo", callable)
      test_baton = stub("Baton")
      it.execute!(test_baton)
      assert_same test_baton, sensor
    end
  end

  context "with a block that throws a disposition" do
    specify "should save and return the disposition" do
      it = SimpleActionItem.new("Failure") do 
        throw(:methodical_disposition, 
          Methodical::Disposition(:in_progress, "Procrastinating", 42))
      end
      assert_equal(Methodical::Disposition(:in_progress, "Procrastinating", 42), 
        it.execute!)
      assert_equal(Methodical::Disposition(:in_progress, "Procrastinating", 42), 
        it.disposition)
    end
  end

  context "with a block that raises a runtime error" do
    specify "has a status of :failed after being called" do
      it = SimpleActionItem.new("Failure") do raise "Fail" end
      it.execute!
      assert_equal :failed, it.status
    end

    specify "stores the exception" do
      it = SimpleActionItem.new("Failure") do raise "Fail" end
      it.execute!
      assert_kind_of RuntimeError, it.error
      assert_equal "Fail", it.error.message
    end

    specify "returns a disposition from call" do
      it = SimpleActionItem.new("Failure") do raise "Fail" end
      assert_kind_of Methodical::Disposition, it.execute!
      assert_equal "Fail", it.execute!.explanation
    end

    specify "details should be derived from the error backtrace" do
      error = RuntimeError.new("Fail")
      error.set_backtrace(['FRAME1', 'FRAME2'])
      it = SimpleActionItem.new("Failure") do raise error end
      assert_equal "FRAME1\nFRAME2", it.execute!.details
    end

  end

  context "with a block that raises a StandardError" do
    specify "has a status of :bad after being called" do
      it = SimpleActionItem.new("Failure") do 
        raise StandardError, "Fail" 
      end
      it.execute!
      assert_equal :bad, it.status
    end

    specify "stores the exception" do
      it = SimpleActionItem.new("Failure") do 
        raise StandardError, "Fail" 
      end
      it.execute!
      assert_kind_of StandardError, it.error
      assert_equal "Fail", it.error.message
    end

    specify "details should be derived from the error backtrace" do
      error = StandardError.new("Fail")
      error.set_backtrace(['FRAME1', 'FRAME2'])
      it = SimpleActionItem.new("Failure") do raise error end
      assert_equal "FRAME1\nFRAME2", it.execute!.details
    end
  end

  context "with a block that raises a Exception" do
    specify "has a status of :bad after being called" do
      it = SimpleActionItem.new("Failure") do 
        raise Exception, "Alert!" 
      end
      begin
        it.execute!
      rescue Exception
      end
      assert_equal :bad, it.status
    end

    specify "stores the exception" do
      it = SimpleActionItem.new("Failure") do 
        raise Exception, "Fail" 
      end
      begin
        it.execute!
      rescue Exception
      end
      assert_kind_of Exception, it.error
      assert_equal "Fail", it.error.message
      assert_equal "Fail", it.explanation
    end

    specify "passes the exception on" do
      it = SimpleActionItem.new("Failure") do 
        raise Exception, "Fail" 
      end
      assert_raises(Exception) do
        it.execute!
      end
    end

    specify "details should be derived from the error backtrace" do
      error = Exception.new("Fail")
      error.set_backtrace(['FRAME1', 'FRAME2'])
      it = SimpleActionItem.new("Failure") do raise error end
      begin
        it.execute!
      rescue Exception
      end
      assert_equal "FRAME1\nFRAME2", it.details
    end

  end

  context "with a block that returns no details" do
    specify "has no explanation" do
      it = SimpleActionItem.new("Foo") {}
      it.execute!
      assert it.explanation.blank?
    end

    specify "returns a disposition on call" do
      it = SimpleActionItem.new("Foo") {}
      assert_kind_of Methodical::Disposition, it.execute!
    end
  end

  context "with a block that returns success details" do
    specify "uses second element for explanation" do
      it = SimpleActionItem.new("Foo") do
        [:succeeded, "EXPLANATION", nil]
      end
      it.execute!
      assert_equal "EXPLANATION", it.explanation
    end

    specify "uses third element for result" do
      it = SimpleActionItem.new("Foo") do
        [:succeeded, "EXPLANATION", {:frobozz => "magic"}]
      end
      it.execute!
      assert_equal({:frobozz => "magic"}, it.result)
    end

    specify "returns a disposition on call" do
      it = SimpleActionItem.new("Foo") do
        [:succeeded, "EXPLANATION", {:frobozz => "magic"}]
      end
      assert_kind_of Methodical::Disposition, it.execute!
    end
  end

  context "with a status of :skipped" do
    specify "can format a status message" do
      it = SimpleActionItem.new("Foo") {}
      it.status = :skipped
      assert_equal "Foo: Skipped.", it.synopsis
    end
  end

  context "with a status of :abort" do
    specify "can format a status message" do
      it = SimpleActionItem.new("Foo") {}
      it.status = :abort
      assert_equal "Foo: Failed.", it.synopsis
    end
  end

  context "with the ignored bit set" do
    specify "knows it is ignored" do
      it = SimpleActionItem.new("Foo") {}
      it.ignored      = true
      assert it.ignored?
    end

    specify "does not count towards overall outcome" do
      it = SimpleActionItem.new("Foo") {}
      it.ignored      = true
      assert !it.relevant?
    end

  end

  context "failed, with the ignored bit set" do
    specify "can format a status message" do
      it = SimpleActionItem.new("Foo") {}
      it.status      = :failed
      it.explanation = "Stuff happened"
      it.ignored     = true
      assert_equal "Foo: Failed (Stuff happened) (Ignored).", it.synopsis
    end

    specify "should say continuing is OK" do
      it = SimpleActionItem.new("Foo") {}
      it.status      = :failed
      it.explanation = "Stuff happened"
      it.ignored     = true
      assert it.continue?
    end

    specify "is not decisive" do
      it = SimpleActionItem.new("Foo") {}
      it.status = :failed
      it.ignored = true
      assert !it.decisive?
    end
  end

  context "aborted, with the ignored bit set" do
    specify "can format a status message" do
      it = SimpleActionItem.new("Foo") {}
      it.status      = :abort
      it.explanation = "Stuff happened"
      it.ignored     = true
      assert_equal "Foo: Failed (Stuff happened) (Ignored).", it.synopsis
    end

    specify "should NOT say continuing is OK" do
      it = SimpleActionItem.new("Foo") {}
      it.status      = :abort
      it.explanation = "Stuff happened"
      it.ignored     = true
      assert !it.continue?
    end

    specify "is not decisive" do
      it = SimpleActionItem.new("Foo") {}
      it.status = :aborted
      it.ignored = true
      assert !it.decisive?
    end
  end

  context "succeeded, with the ignored bit set" do
    specify "can format a status message" do
      it = SimpleActionItem.new("Foo") {}
      it.status      = :succeeded
      it.explanation = "Stuff happened"
      it.ignored     = true
      assert_equal "Foo: OK (Stuff happened).", it.synopsis
    end

    specify "should say continuing is OK" do
      it = SimpleActionItem.new("Foo") {}
      it.status      = :succeeded
      it.explanation = "Stuff happened"
      it.ignored     = true
      assert it.continue?
    end
  end

  context "with a status of :sufficient" do
    specify "can format a status message" do
      it = SimpleActionItem.new("Foo") {}
      it.status = :sufficient
      assert_equal "Foo: OK.", it.synopsis
    end
  end

  context "with a status of :finish" do
    specify "can format a status message" do
      it = SimpleActionItem.new("Foo") {}
      it.status = :finish
      assert_equal "Foo: OK.", it.synopsis
    end

    specify "should NOT approve continuation" do
      it = SimpleActionItem.new("Foo") {}
      it.status = :finish
      assert !it.continue?
    end
  end

  context "with a block that returns a single value" do
    specify "has no explanation" do
      it = SimpleActionItem.new("Foo") do
        "RESULT"
      end
      it.execute!
      assert it.explanation.blank?
    end

    specify "uses value for result" do
      it = SimpleActionItem.new("Foo") do
        "RESULT"
      end
      it.execute!
      assert_equal("RESULT", it.result)
    end
  end

  context "which has failed" do
    specify "knows it has failed" do
      it = SimpleActionItem.new("Failure") do raise "Fail" end
      it.execute!
      assert it.failed?
    end

    specify "knows it has not succeeded" do
      it = SimpleActionItem.new("Failure") do raise "Fail" end
      it.execute!
      assert !it.succeeded?
    end

    specify "is decisive" do
      it = SimpleActionItem.new("Failure") do raise "Fail" end
      it.execute!
      assert it.decisive?
    end

    specify "knows it is not bad" do
      it = SimpleActionItem.new("Fail") do raise "Fail" end
      it.execute!
      assert !it.bad?
    end

    specify "gets explanation from error" do
      it = SimpleActionItem.new("Fail") do raise "Fail" end
      it.execute!
      assert_equal "Fail", it.explanation
    end

    specify "can format a status message" do
      it = SimpleActionItem.new("Foo") do raise "MESSAGE" end
      it.execute!
      assert_equal "Foo: Failed (MESSAGE).", it.synopsis
    end
  end

  context "which has raised a standard error" do
    specify "knows it has failed" do
      it = SimpleActionItem.new("Failure") do 
        raise StandardError, "Fail" 
      end
      it.execute!
      assert it.failed?
    end

    specify "knows it has not succeeded" do
      it = SimpleActionItem.new("Failure") do 
        raise StandardError, "Fail" 
      end
      it.execute!
      assert !it.succeeded?
    end

    specify "knows it is bad" do
      it = SimpleActionItem.new("Fail") do 
        raise StandardError, "Fail" 
      end
      it.execute!
      assert it.bad?
    end

    specify "gets explanation from error" do
      it = SimpleActionItem.new("Fail") do raise StandardError, "Fail" end
      it.execute!
      assert_equal "Fail", it.explanation
    end

    specify "can format a status message" do
      it = SimpleActionItem.new("Foo") do 
        raise StandardError, "SOME_ERROR" 
      end
      it.execute!
      assert_equal "Foo: Error (SOME_ERROR).", it.synopsis
    end
  end

  context "which has succeeded" do
    specify "knows it has not failed" do
      it = SimpleActionItem.new("Success") do end
      it.execute!
      assert !it.failed?
    end

    specify "knows it has succeeded" do
      it = SimpleActionItem.new("Success") do end
      it.execute!
      assert it.succeeded?
    end

    specify "knows it is not bad" do
      it = SimpleActionItem.new("Success") do end
      it.execute!
      assert !it.bad?
    end

    specify "can format a status message" do
      it = SimpleActionItem.new("Foo") {}
      it.execute!
      assert_equal "Foo: OK.", it.synopsis
    end

  end

  context "#succeed!" do
    specify "throws :methodical_disposition" do
      it = SimpleActionItem.new("TEST") {}
      assert_throws(:methodical_disposition) do
        it.succeed!
      end
    end

    specify "throws a disposition object" do
      it = SimpleActionItem.new("TEST") {}
      assert_kind_of(Methodical::Disposition, 
        catch(:methodical_disposition) { it.succeed! })
    end

    specify "throws a successful disposition" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal(:succeeded,
        catch(:methodical_disposition) { it.succeed! }.status)
    end

    specify "throws the given explanation" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal("EXPL",
            catch(:methodical_disposition) { it.succeed!("EXPL") }.explanation)
    end

    specify "throws the given result" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal(42,
            catch(:methodical_disposition) { it.succeed!("EXPL", 42) }.result)
    end

    specify "throws the given details" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal("DETAILS",
            catch(:methodical_disposition) { 
          it.succeed!("EXPL", 42, "DETAILS") 
        }.details)
    end
  end

  context "#failed!" do
    specify "throws :methodical_disposition" do
      it = SimpleActionItem.new("TEST") {}
      assert_throws(:methodical_disposition) do
        it.fail!
      end
    end

    specify "throws a disposition object" do
      it = SimpleActionItem.new("TEST") {}
      assert_kind_of(Methodical::Disposition, 
        catch(:methodical_disposition) { it.fail! })
    end

    specify "throws a failed disposition" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal(:failed,
        catch(:methodical_disposition) { it.fail! }.status)
    end

    specify "throws the given explanation" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal("EXPL",
            catch(:methodical_disposition) { it.fail!("EXPL") }.explanation)
    end

    specify "throws the given result" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal(42,
            catch(:methodical_disposition) { it.fail!("EXPL", 42) }.result)
    end

    specify "throws the given error" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal("FOO",
            catch(:methodical_disposition) { 
          it.fail!("EXPL", 42, RuntimeError.new("FOO")) 
        }.error.message)
    end

    specify "throws the given details" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal("DETAILS",
            catch(:methodical_disposition) { 
          it.fail!("EXPL", 42, nil, "DETAILS") 
        }.details)
    end
  end

  context "#skip!" do
    specify "throws :methodical_disposition" do
      it = SimpleActionItem.new("TEST") {}
      assert_throws(:methodical_disposition) do
        it.skip!
      end
    end

    specify "throws a disposition object" do
      it = SimpleActionItem.new("TEST") {}
      assert_kind_of(Methodical::Disposition, 
        catch(:methodical_disposition) { it.skip! })
    end

    specify "throws a skipped disposition" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal(:skipped,
        catch(:methodical_disposition) { it.skip! }.status)
    end

    specify "throws the given explanation" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal("EXPL",
            catch(:methodical_disposition) { it.skip!("EXPL") }.explanation)
    end

    specify "throws the given details" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal("DETAILS",
            catch(:methodical_disposition) { 
          it.skip!("EXPL", "DETAILS") 
        }.details)
    end
  end

  context "#checkpoint!" do
    specify "throws :methodical_disposition" do
      it = SimpleActionItem.new("TEST") {}
      assert_throws(:methodical_disposition) do
        it.checkpoint!
      end
    end

    specify "throws a disposition object" do
      it = SimpleActionItem.new("TEST") {}
      assert_kind_of(Methodical::Disposition, 
        catch(:methodical_disposition) { it.checkpoint! })
    end

    specify "throws an in_progress disposition" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal(:in_progress,
        catch(:methodical_disposition) { it.checkpoint! }.status)
    end

    specify "throws the given explanation" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal("EXPL",
            catch(:methodical_disposition) { it.checkpoint!("EXPL") }.explanation)
    end

    specify "throws the given memento" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal(42,
            catch(:methodical_disposition) { it.checkpoint!("EXPL", 42) }.memento)
    end

    specify "throws the given details" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal("DETAILS",
            catch(:methodical_disposition) { 
          it.checkpoint!("EXPL", 42, "DETAILS") 
        }.details)
    end
  end


  context "#sufficient!" do
    specify "throws :methodical_disposition" do
      it = SimpleActionItem.new("TEST") {}
      assert_throws(:methodical_disposition) do
        it.sufficient!
      end
    end

    specify "throws a disposition object" do
      it = SimpleActionItem.new("TEST") {}
      assert_kind_of(Methodical::Disposition, 
        catch(:methodical_disposition) { it.sufficient! })
    end

    specify "throws a sufficient disposition" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal(:sufficient,
        catch(:methodical_disposition) { it.sufficient! }.status)
    end

    specify "throws the given explanation" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal("EXPL",
            catch(:methodical_disposition) { it.sufficient!("EXPL") }.explanation)
    end

    specify "throws the given result" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal(42,
            catch(:methodical_disposition) { it.sufficient!("EXPL", 42) }.result)
    end

    specify "throws the given details" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal("DETAILS",
            catch(:methodical_disposition) { 
          it.sufficient!("EXPL", 42, "DETAILS") 
        }.details)
    end
  end

  context "#finish!" do
    specify "throws :methodical_disposition" do
      it = SimpleActionItem.new("TEST") {}
      assert_throws(:methodical_disposition) do
        it.finish!
      end
    end

    specify "throws a disposition object" do
      it = SimpleActionItem.new("TEST") {}
      assert_kind_of(Methodical::Disposition, 
        catch(:methodical_disposition) { it.finish! })
    end

    specify "throws a finish disposition" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal(:finish,
        catch(:methodical_disposition) { it.finish! }.status)
    end

    specify "throws the given explanation" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal("EXPL",
            catch(:methodical_disposition) { it.finish!("EXPL") }.explanation)
    end

    specify "throws the given result" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal(42,
            catch(:methodical_disposition) { it.finish!("EXPL", 42) }.result)
    end

    specify "throws the given details" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal("DETAILS",
            catch(:methodical_disposition) { 
          it.finish!("EXPL", 42, "DETAILS") 
        }.details)
    end
  end

  context "#abort!" do
    specify "throws :methodical_disposition" do
      it = SimpleActionItem.new("TEST") {}
      assert_throws(:methodical_disposition) do
        it.abort!
      end
    end

    specify "throws a disposition object" do
      it = SimpleActionItem.new("TEST") {}
      assert_kind_of(Methodical::Disposition, 
        catch(:methodical_disposition) { it.abort! })
    end

    specify "throws an abort disposition" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal(:abort,
        catch(:methodical_disposition) { it.abort! }.status)
    end

    specify "throws the given explanation" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal("EXPL",
            catch(:methodical_disposition) { it.abort!("EXPL") }.explanation)
    end

    specify "throws the given result" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal(42,
            catch(:methodical_disposition) { it.abort!("EXPL", 42) }.result)
    end

    specify "throws the given error" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal("FOO",
            catch(:methodical_disposition) { 
          it.abort!("EXPL", 42, RuntimeError.new("FOO")) 
        }.error.message)
    end

    specify "throws the given details" do
      it = SimpleActionItem.new("TEST") {}
      assert_equal("DETAILS",
            catch(:methodical_disposition) { 
          it.abort!("EXPL", 42, nil, "DETAILS") 
        }.details)
    end
  end
end
