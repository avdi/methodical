require 'delegate'
require 'methodical/walkthrough'

module Methodical
  class Checklist < DelegateClass(Array)
    attr_reader :title

    def initialize(title)
      @title = title
      super([])
    end

    def new_walkthrough
      Walkthrough.new(self)
    end

    def perform_walkthrough!(baton=nil, raise_on_error=false, &block)
      walkthrough = new_walkthrough
      walkthrough.perform!(baton, raise_on_error, &block)
      walkthrough
    end

    def <<(object)
      raise ArgumentError, "No nils allowed" if object.nil?
      super(object)
      object
    end
  end
end
