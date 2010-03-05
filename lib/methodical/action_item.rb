require 'forwardable'
require 'methodical/disposition'
require 'methodical/executable'

module Methodical
  class ActionItem
    include Executable
    extend Forwardable

    attr_reader   :title
    attr_reader   :error
    attr_writer   :ignored
    attr_reader   :disposition
    attr_accessor :walkthrough

    def_delegators :disposition, 
                   :status, 
                   :status=,
                   :explanation,
                   :explanation=,
                   :result,
                   :result=,
                   :error,
                   :error=,
                   :details,
                   :details=,
                   :succeeded?,
                   :failed?,
                   :bad?,
                   :done?,
                   :halted?,
                   :done_and_ok?

    def initialize(title)
      @title          = title
      @ignored        = false
      @disposition    = Disposition.new([:not_started, "", nil])
      @raise_on_error = false
    end

    def to_s
      synopsis
    end

    def synopsis
      "#{title}: #{human_status}" + 
        (explanation.blank? ? "." : " (#{explanation})#{ignored_suffix}.")
    end

    def inspect
      "##<#{self.class.name}:#{title}:#{object_id}>"
    end

    def human_status
      case status
      when :failed, :abort                     then "Failed"
      when :bad                                then "Error"
      when :succeeded, :sufficient, :finish    then "OK"
      when :in_progress                        then "In progress"
      when :not_started                        then "Not started"
      when :skipped                            then "Skipped"
      else raise "Invalid status #{status.inspect}"
      end
    end

    def ignored?
      @ignored
    end

    def relevant?
      !ignored?
    end

    def continue?
      disposition.continuable?
    end

    def decisive?
      !ignored? && disposition.decisive?
    end

    def update!(status, explanation, result, error=nil, details="")
      self.status      = status
      self.explanation = explanation
      self.result      = result
      self.error       = error
      self.details     = details
      disposition
    end

    # Disposition methods
    def succeed!(explanation="", result=nil, details="")
      throw(:methodical_disposition, 
        Methodical::Disposition(:succeeded, explanation, result, nil, details))
    end

    def fail!(explanation="", result=nil, error=nil, details="")
      throw(:methodical_disposition, 
        Methodical::Disposition(:failed, explanation, result, error, details))
    end

    def skip!(explanation="", details="")
      throw(:methodical_disposition, 
        Methodical::Disposition(:skipped, explanation, nil, nil, details))
    end

    def checkpoint!(explanation="", memento=nil, details="")
      throw(:methodical_disposition, 
        Methodical::Disposition(:in_progress, explanation, memento, nil, details))
    end

    def sufficient!(explanation="", result=nil, details="")
      throw(:methodical_disposition, 
        Methodical::Disposition(:sufficient, explanation, result, nil, details))
    end

    def finish!(explanation="", result=nil, details="")
      throw(:methodical_disposition, 
        Methodical::Disposition(:finish, explanation, result, nil, details))
    end

    def abort!(explanation="", result=nil, error=nil, details="")
      throw(:methodical_disposition, 
        Methodical::Disposition(:abort, explanation, result, error, details))
    end

    protected
    
    private

    def ignored_suffix
      if ignored? && failed?
        " (Ignored)"
      else
        ""
      end
    end
  end
end
