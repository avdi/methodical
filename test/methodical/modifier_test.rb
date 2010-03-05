require File.expand_path("../test_helper", File.dirname(__FILE__))
require 'methodical/modifier'
require 'methodical/action_item'

class ModifierTest < Test::Unit::TestCase
  context "#execute!" do
    specify "executes the modifier block" do
      step = stub_everything("ActionItem")
      sensor = :unset
      it = Methodical::Modifier.new("NAME", step) do
        sensor = :set
      end
      it.execute!
      assert_equal :set, sensor
    end

    specify "passes the action item to the block" do
      step = stub_everything("ActionItem")
      sensor = :unset
      it = Methodical::Modifier.new("NAME", step) do |action_item, baton|
        sensor = action_item
      end
      it.execute!
      assert_same step, sensor
    end

    specify "passes a baton to the block" do
      baton = stub("Baton")
      step = stub_everything("ActionItem")
      sensor = :unset
      it = Methodical::Modifier.new("NAME", step) do |action_item, baton|
        sensor = baton
      end
      it.execute!(baton)
      assert_not_nil sensor
      assert_same baton, sensor
    end
  end

  context "#<<" do
    specify "composes modifier and modified" do
      step = stub_everything("ActionItem")
      it = Methodical::Modifier.new("NAME")
      it << step
      assert_same step, it.action_item
    end

    specify "returns the modifier" do
      step = stub_everything("ActionItem")
      it = Methodical::Modifier.new("NAME")
      assert_same it, (it << step)
    end

    specify "delegates to action_item, if set" do
      mod2 = stub("Inner Modifier")
      step = stub_everything("ActionItem")
      it = Methodical::Modifier.new("NAME", mod2)
      mod2.expects(:<<).with(step)
      it << step
    end
  end

  context "#clone" do
    specify "deeply copies action item" do
      step = stub_everything("ActionItem")
      copy = stub_everything("Copy")
      it = Methodical::Modifier.new("NAME", step)
      step.expects(:clone).returns(copy).at_least_once
      assert_same copy, it.clone.action_item
    end
  end

  specify "delegates unknown methods to action item" do
    step = stub_everything("ActionItem")
    it = Methodical::Modifier.new("NAME", step)
    step.expects(:foo).with("bar")
    it.foo("bar")
  end
end
