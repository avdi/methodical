module Methodical
  module Executable
    attr_writer   :raise_on_error

    # Default exception handling:
    # * RuntimeErrors are considered failures. The exception will be captured
    #   and not re-raised.
    # * StandardErrors are considered indicative of a programming error in the
    #   action.  The action will be marked as bad and failure recorded; but the
    #   exception will not be re-thrown.
    # * Exceptions not caught by the other cases are considered fatal errors.
    #   The step will be marked bad and the error recorded, and the exception
    #   will then be re-raised.
    def execute!(baton=nil, raise_on_error=raise_on_error?)
      disposition = catch_disposition do
        call(baton, self)
      end
    rescue RuntimeError => error
      disposition = save_and_return_disposition(:failed, error.message, nil, error)
      raise if raise_on_error
      disposition
    rescue StandardError => error
      disposition = save_and_return_disposition(:bad, error.message, nil, error)
      raise if raise_on_error
      disposition
    rescue Exception => error
      save_and_return_disposition(:bad, error.message, nil, error)
      raise
    else
      save_and_return_disposition(
        disposition.status, 
        disposition.explanation, 
        disposition.result,
        nil, 
        disposition.details)
    end

    def catch_disposition
      result = catch(:methodical_disposition) do
        yield
      end
      Methodical::Disposition(result)
    end

    def raise_on_error?
      defined?(@raise_on_error) ? @raise_on_error : false
    end

    private

    def save_and_return_disposition(status, explanation, result, error, details="")
      details = if details.blank? && error
                  error.backtrace.join("\n")
                else
                  details
                end
      update!(status, explanation, result, error, details)
    end

  end
end
