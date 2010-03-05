require 'delegate'
require 'methodical/executable'

module Methodical
  class Modifier < SimpleDelegator
    include Executable

    def initialize(name, action_item=nil, &block)
      @name        = name
      __setobj__(action_item)
      @block       = block
    end

    def to_s
      "<#{@name}>(#{action_item.to_s})"
    end

    def call(baton=nil, raise_on_error=false)
      @block.call(action_item, baton)
    end

    def <<(rhs)
      if self.action_item
        self.action_item << rhs
      else
        self.action_item = rhs
      end
      self
    end

    if RUBY_VERSION=='1.8.6'
      def clone
        the_clone = Object.instance_method(:clone).bind(self).call
        the_clone.__setobj__(__getobj__.clone)
        the_clone
      end
    end

    alias_method :action_item, :__getobj__
    alias_method :action_item=, :__setobj__

  end
end
