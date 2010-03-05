require 'arrayfields'

module Methodical
  def self.Disposition(*args)
    if args.size == 1
      object = args.first
      if Disposition === object
        object
      elsif object.kind_of?(Array)     && 
          object.size >= 2             &&
          object[0].kind_of?(Symbol)   &&
          object[1].kind_of?(String)
        Disposition.new(object)
      else
        Disposition.new([:succeeded, "", object])
      end
    else
      Disposition.new(args)
    end
  end

  Disposition = Array.struct :status, :explanation, :result, :error, :details

  # A Disposition represents the status of an ActionItem (step)
  #
  # Explanation of statuses:
  #
  # * not_started: The action has not yet been performed
  # * in_progress: The action has been started, and has not finished.
  # * succeeded:   The action succeeded. If all actions succeed, the walkthrough
  #                is considered a success.
  # * failed:      The action failed. The walkthrough will fail unless the
  #                "ignored" flag was set; but the walkthrough will not be
  #                halted.
  # * sufficient:  The action succeeded. Later steps will be executed, but
  #                the walkthrough will be a success even if there are later
  #                failures.
  # * finish:      The action succeeded.  No more steps will be performed.
  # * abort:       The action failed, and no more steps will be performed.
  # * bad:         An error occured outside of the range of any expected failure
  #                modes. The walkthrough will continue, but will be marked as
  #                failed.
  # * skipped:     The action was skipped. The "explanation" field should
  #                contain the reason for skipping the action.
  class Disposition
    VALID_STATUSES = [
      :not_started,
      :in_progress,
      :succeeded,
      :failed,
      :sufficient,
      :finish,
      :abort,
      :bad,
      :skipped
    ]

    alias_method :base_initialize, :initialize
    def initialize(*args)
      base_initialize(*args)
      self.details ||= ""
      validate!
    end

    alias_method :memento, :result
    alias_method :memento=, :result=

    def ok?
      !failed?
    end

    def failed?
      [:failed, :bad, :abort].include?(status)
    end

    def succeeded?
      [:succeeded, :sufficient, :finish].include?(status)
    end

    def bad?
      status == :bad
    end

    def skipped?
      status == :skipped
    end

    def done?
      succeeded? || failed? || skipped?
    end

    def continuable?
      !halted?
    end

    def halted?
      status == :abort || status == :finish
    end

    def decisive?
      [:sufficient, :finish, :failed, :bad, :abort].include?(status)
    end

    def done_and_ok?
      done? && ok?
    end

    def merge(params)
      params.inject(self.class.new(self)) {|d, (k,v)| d[k] = v; d}
    end

    private

    def validate!
      unless VALID_STATUSES.include?(status)
        raise ArgumentError, "Invalid status #{status.inspect}" 
      end
      unless explanation.kind_of?(String)
        raise ArgumentError, "Explanation must be a String"
      end
      if result.kind_of?(Exception)
        raise ArgumentError, "Result must not be an Exception"
      end
      if error && !error.kind_of?(Exception)
        raise ArgumentError, "Error must be an Exception"
      end
      unless details.kind_of?(String)
        raise ArgumentError, "Details must be a String"
      end
    end
  end
end
