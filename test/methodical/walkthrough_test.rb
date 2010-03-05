require File.expand_path("../test_helper", File.dirname(__FILE__))
require 'methodical/walkthrough'
require 'methodical/disposition'
require 'methodical/simple_action_item'

class ActionItemTest < Test::Unit::TestCase
  def create_disposition(status)
    Methodical::Disposition.new([status, "", nil])
  end

  def create_step(status)
    step = Methodical::SimpleActionItem.new("#{status} step") {
      [status, "", nil]
    }

    # Making #dup return self simplifies setting expectations
    def step.clone
      self
    end
    step
  end
  
  def create_succeeding_step
    create_step(:succeeded)
  end

  def create_failing_step
    create_step(:failed)
  end

  def create_bad_step
    create_step(:bad)
  end

  def create_skipped_step
    create_step(:skipped)
  end

  def create_sufficient_step
    create_step(:sufficient)
  end

  def create_aborting_step
    create_step(:abort)
  end

  def create_finishing_step
    create_step(:finish)
  end
  
  context "given a checklist" do
    specify "gets its title from the checklist" do
      checklist = stub_everything("Checklist", :title => "TITLE", :map => [])
      it = Methodical::Walkthrough.new(checklist)
      assert_equal "TITLE", it.title
    end

    specify "starts in the :not_started state" do
      it = Methodical::Walkthrough.new([])
      assert !it.started?
    end
  end

  context "given some steps" do 
    specify "sets step walkthroughs to self" do
      step1 = create_succeeding_step
      step2 = create_succeeding_step
      it = Methodical::Walkthrough.new([step1, step2])
      assert_same it, it[0].walkthrough
      assert_same it, it[1].walkthrough
    end
   
  end

  context "#perform!" do
    specify "updates status callback before and after each step" do
      step1 = create_skipped_step
      step2 = create_succeeding_step
      step3 = create_aborting_step
      step4 = create_succeeding_step

      sensor = stub("Sensor")
      baton  = stub("Baton")
      
      it = Methodical::Walkthrough.new([
          step1, step2, step3, step4
        ])

      sensor.expects(:update).with(it, 0, step1, baton).in_sequence
      step1.expects(:call).returns(create_disposition(:skipped)).in_sequence
      sensor.expects(:update).with(it, 0, step1, baton).in_sequence

      sensor.expects(:update).with(it, 1, step2, baton).in_sequence
      step2.expects(:call).returns(create_disposition(:succeeded)).in_sequence
      sensor.expects(:update).with(it, 1, step2, baton).in_sequence

      sensor.expects(:update).with(it, 2, step3, baton).in_sequence
      step3.expects(:call).returns(create_disposition(:abort)).in_sequence
      sensor.expects(:update).with(it, 2, step3, baton).in_sequence

      sensor.expects(:update).with(it, 3, step4, baton).in_sequence
      step4.expects(:call).never
      sensor.expects(:update).with(it, 3, step4, baton).in_sequence

      it.perform!(baton) do |*args|
        sensor.update(*args)
      end
    end

    specify "saves baton" do
      baton  = stub("Baton")
      
      it = Methodical::Walkthrough.new([])
      it.perform!(baton)
      assert_same baton, it.baton
    end
  end

  context "#basic_report" do
    specify "includes a list of synopses" do
      it = Methodical::Walkthrough.new([
          stub(:clone => stub_everything(:synopsis => "SYNOPSIS1")),
          stub(:clone => stub_everything(:synopsis => "SYNOPSIS2")),
          stub(:clone => stub_everything(:synopsis => "SYNOPSIS3")),
        ])
      assert_equal "SYNOPSIS1\nSYNOPSIS2\nSYNOPSIS3\n", it.basic_report
    end
  end

  context "with no steps" do
    specify "ends in the :succeeded state" do
      it = Methodical::Walkthrough.new([])
      it.perform!
      assert it.succeeded?
    end
  end

  context "with succeeding steps" do
    specify "ends in the :succeeded state" do
      it = Methodical::Walkthrough.new([create_succeeding_step])
      it.perform!
      assert it.succeeded?
    end

    specify "considers the last step decisive" do
      it = Methodical::Walkthrough.new([create_succeeding_step])
      it.perform!
      assert_equal 0, it.decisive_index
    end
  end

  context "interrupted in the middle" do
    specify "is in the :in_progress state" do
      step = create_succeeding_step
      step.stubs(:call).raises(SignalException.new("INT"))
      it = Methodical::Walkthrough.new([step])
      begin
        it.perform!
      rescue SignalException
      end
      assert_equal :in_progress, it.status
      assert it.in_progress?
      assert !it.succeeded?
      assert !it.failed?
      assert !it.finished?
    end
  end

  context "with a failing step" do
    specify "ends in the :failed state" do
      it = Methodical::Walkthrough.new([create_failing_step])
      it.perform!
      assert_equal :failed, it.status
    end

    specify "considers the last step decisive" do
      it = Methodical::Walkthrough.new([create_failing_step])
      it.perform!
      assert_equal 0, it.decisive_index
    end
  end

  context "with a bad step" do
    specify "ends in the :failed state" do
      it = Methodical::Walkthrough.new([create_bad_step])
      it.perform!
      assert_equal :failed, it.status
    end

    specify "considers the last step decisive" do
      it = Methodical::Walkthrough.new([create_failing_step])
      it.perform!
      assert_equal 0, it.decisive_index
    end
  end

  context "with steps that fail, then succeed" do
    specify "ends in the :failed state" do
      it = Methodical::Walkthrough.new([
          create_failing_step,
          create_succeeding_step
        ])
      it.perform!
      assert_equal :failed, it.status
    end

    specify "has one failed step" do
      it = Methodical::Walkthrough.new([
          fail_step = create_failing_step,
          create_succeeding_step
        ])
      it.perform!
      assert_equal [fail_step], it.failed_steps
    end

    # specify "does not set the ignore bit on the second step" do
    #   it = Methodical::Walkthrough.new([
    #       create_failing_step,
    #       step2 = stub_everything(:call => create_disposition(:succeeded))
    #     ])
    #   step2.expects(:ignored=).never
    #   it.perform!
    # end

    specify "considers the first step to be the decisive step" do
      it = Methodical::Walkthrough.new([
          create_failing_step,
          create_succeeding_step
        ])
      it.perform!
      assert_equal 0, it.decisive_index
    end

  end

  context "with steps that succeed, then fail" do
    specify "ends in the :failed state" do
      it = Methodical::Walkthrough.new([
          create_succeeding_step,
          create_failing_step,
        ])
      it.perform!
      assert_equal :failed, it.status
    end

    specify "considers the last step to be the decisive step" do
      it = Methodical::Walkthrough.new([
          create_succeeding_step,
          create_failing_step,
        ])
      it.perform!
      assert_equal 1, it.decisive_index
    end
  end

  context "with a skipped step" do
    specify "ends in the :succeeded state" do
      it = Methodical::Walkthrough.new([
          create_skipped_step
        ])
      it.perform!
      assert_equal :succeeded, it.status
    end

  end

  context "with an aborting step preceding a succeding step" do
    specify "ends in the :failed state" do
      it = Methodical::Walkthrough.new([
          create_aborting_step,
          create_succeeding_step
        ])
      it.perform!
      assert_equal :failed, it.status
    end

    specify "does not execute second step" do
      it = Methodical::Walkthrough.new([
          create_aborting_step,
          step2 = stub_everything("Succeeding Step")
        ])
      step2.expects(:call).never
      it.perform!
    end

    specify "updates status of skipped step" do
      it = Methodical::Walkthrough.new([
          create_aborting_step,
          step2 = stub_everything("Succeeding Step")
        ])
      step2.expects(:update!).
        with(:skipped, "Run aborted by prior step", nil)
      it.perform!
    end

    specify "considers the aborted step the decisive step" do
      it = Methodical::Walkthrough.new([
          create_aborting_step,
          create_succeeding_step
        ])
      it.perform!
      assert_equal 0, it.decisive_index
    end
  end

  context "with a finishing step preceding a succeding step" do
    specify "ends in the :succeeded state" do
      it = Methodical::Walkthrough.new([
          create_finishing_step,
          create_succeeding_step
        ])
      it.perform!
      assert_equal :succeeded, it.status
    end

    specify "does not execute second step" do
      it = Methodical::Walkthrough.new([
          create_finishing_step,
          step2 = stub_everything("Succeeding Step")
        ])
      step2.expects(:call).never
      it.perform!
    end

    specify "updates status of skipped step" do
      it = Methodical::Walkthrough.new([
          create_finishing_step,
          step2 = stub_everything("Succeeding Step")
        ])
      step2.expects(:update!).
        with(:skipped, "Satisfied by prior step", nil)
      it.perform!
    end

    specify "considers the finishing step the decisive step" do
      it = Methodical::Walkthrough.new([
          create_finishing_step,
          create_succeeding_step
        ])
      it.perform!
      assert_equal 0, it.decisive_index
    end
  end

  context "with a sufficient step preceding a failing step" do
    specify "ends in the :succeeded state" do
      it = Methodical::Walkthrough.new([
          create_sufficient_step,
          create_failing_step
        ])
      it.perform!
      assert_equal :succeeded, it.status
    end

    specify "executes second step" do
      it = Methodical::Walkthrough.new([
          create_sufficient_step,
          step2 = stub_everything("Failing Step")
        ])
      step2.expects(:execute!).
        returns(create_disposition(:failed))
      it.perform!
    end

    specify "sets ignore bit on second step" do
      it = Methodical::Walkthrough.new([
          create_sufficient_step,
          step2 = stub_everything("Failing Step", 
            :execute! => create_disposition(:failed))
        ])
      step2.expects(:ignored=).with(true)
      it.perform!
    end

    specify "considers the sufficient step the decisive step" do
      it = Methodical::Walkthrough.new([
          create_sufficient_step,
          create_succeeding_step
        ])
      it.perform!
      assert_equal 0, it.decisive_index
    end


  end

end
