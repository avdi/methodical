require 'methodical/action_item'

module Methodical
  class SimpleActionItem < ActionItem
    extend Forwardable

    def initialize(title, callable=nil, &block)
      unless(!!callable ^ !!block)
        raise ArgumentError, "Either a callable or a block must be provided"
      end
      @block       = callable || block
      super(title)
    end

    def call(baton, step)
      @block.call(baton, step)
    end

    def ==(other)
      self.block.eql?(other.block)
    end

    protected
    
    attr_reader :block

    private

  end
end
