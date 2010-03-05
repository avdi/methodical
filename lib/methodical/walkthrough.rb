require 'delegate'
require 'forwardable'

module Methodical
  class Walkthrough < DelegateClass(Array)
    extend Forwardable

    attr_reader :checklist
    attr_reader :next_step_index
    attr_reader :last_step_index
    attr_reader :baton
    attr_reader :index
    attr_reader :decisive_index

    def_delegators :checklist, :title

    def initialize(checklist, baton=nil)
      @checklist       = checklist
      @continue        = true
      @baton           = baton
      @index           = 0
      @decisive_index  = nil
      @halted          = false
      @started         = false
      super(Array.new(checklist.map{|ai| ai.clone}))
      each do |step|
        step.walkthrough = self
      end
    end

    def perform!(baton=@baton, raise_on_error=false, &block)
      @baton  = baton
      until done?
        self.next!(baton, raise_on_error, &block)
      end
    end

    def next!(baton=@baton, raise_on_error=false)
      raise "Already performed" if done?

      @started = true

      action_item = fetch(index)
      yield(self, index, action_item, baton) if block_given?

      execute_or_update_step(action_item, baton, raise_on_error)

      @decisive_index = index if action_item.decisive?
      @halted         = true if action_item.halted?

      yield(self, index, action_item, baton) if block_given?
      advance!
    end

    def inspect
      "##<#{self.class.name}:#{title}:#{object_id}>"
    end

    def basic_report
      inject(""){|report, action_item| 
        report << action_item.synopsis << "\n"
      }
    end

    def failed_steps
      find_all{|step| step.failed?}
    end

    def decisive_step
      decided? ? fetch(decisive_index) : nil
    end

    def status
      if !started? then :not_started
      elsif !decided? then :in_progress
      elsif succeeded? then :succeeded
      else  :failed
      end
    end

    def failed?
      decided? && !decisive_step.done_and_ok?
    end
    
    def succeeded?
      return true if empty?
      decided? && decisive_step.done_and_ok?
    end

    def done?
      index >= size
    end
    alias_method :finished?, :done?

    def decided?
      !!decisive_index
    end

    def halted?
      @halted
    end

    def in_progress?
      started? && !done?
    end

    def started?
      @started
    end

    private

    def advance!
      @index += 1
      if @index >= size
        @decisive_index ||= (size - 1)
      end
    end

    def continue?
      !done? && !halted?
    end

    def execute_or_update_step(step, baton, raise_on_error)
      if decided?
        step.ignored = true
      end

      if continue?
        step.raise_on_error = raise_on_error
        step.execute!(baton, raise_on_error)
      else
        reason = if failed?
                   "Run aborted by prior step"
                 else
                   "Satisfied by prior step"
                 end
        step.update!(:skipped, reason, nil)
      end
    end

  end
end
