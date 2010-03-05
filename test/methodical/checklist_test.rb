require File.expand_path("../test_helper", File.dirname(__FILE__))
require 'methodical/checklist'
require 'methodical/dsl'

class ActionItemTest < Test::Unit::TestCase
  include Methodical::DSL

  context "with no action items" do
    specify "has a title" do
      it = Methodical::Checklist.new("My Checklist")
      assert_equal "My Checklist", it.title
    end

    specify "knows it has no items" do
      it = Methodical::Checklist.new("My Checklist")
      assert_equal 0, it.size
    end

  end

  context "with three action items" do
    specify "knows it has three items" do
      it = Methodical::Checklist.new("My Checklist")
      it << stub("ActionItem 1")
      it << stub("ActionItem 2")
      it << stub("ActionItem 3")
      assert_equal 3, it.size
    end
  end

  context "#perform_walkthrough" do
    specify "returns step list as Walkthrough object" do
      it = Methodical::Checklist.new("My Checklist")
      assert_kind_of Methodical::Walkthrough, it.perform_walkthrough!
    end

    specify "creates, performs, and returns a new walkthrough" do
      sensor = :unset
      walkthrough = stub("Walkthrough")
      it = Methodical::Checklist.new("My Checklist")

      Methodical::Walkthrough.expects(:new).with(it).returns(walkthrough)
      walkthrough.expects(:perform!).with("BATON", false).yields(42)

      result = it.perform_walkthrough!("BATON") do |*args| 
        sensor = args
      end
      assert_equal [42], sensor
      assert_same  walkthrough, result
    end
  end

  context "#new_walkthrough" do
    specify "returns a Walkthrough" do
      it = Methodical::Checklist.new("My Checklist")
      assert_kind_of Methodical::Walkthrough, it.new_walkthrough
    end

    specify "populates the returned walkthrough" do
      it = Methodical::Checklist.new("My Checklist")
      it << stub("ActionItem 1", :clone => a1 = stub_everything("ActionItem 1b"))
      it << stub("ActionItem 2", :clone => a2 = stub_everything("ActionItem 2b") )
      it << stub("ActionItem 3", :clone => a3 = stub_everything("ActionItem 3b"))
      assert_equal [a1, a2, a3], it.new_walkthrough
    end

    specify "does not execute the returned walkthrough" do
      it = Methodical::Checklist.new("My Checklist")
      it << stub("ActionItem 1", :clone => a1 = stub_everything("ActionItem 1b"))
      a1.expects(:call).never
      it.new_walkthrough
    end

    specify "returns a walkthrough which points back to the checklist" do
      it = Methodical::Checklist.new("My Checklist")
      assert_same it, it.new_walkthrough.checklist
    end
  end
end
