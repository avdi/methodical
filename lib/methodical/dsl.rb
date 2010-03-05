require 'methodical/simple_action_item'
require 'methodical/modifier'

module Methodical
  module DSL
    def action(title, &block)
      SimpleActionItem.new(title, &block)
    end

    def sufficient
      Modifier.new("Sufficient") do |action_item, baton|
        disposition = action_item.execute!(baton)
        if(disposition.status == :succeeded)
          disposition.merge(:status => :sufficient)
        else
          disposition
        end
      end
    end

    def requisite
      Modifier.new("Requisite") do |action_item, baton|
        disposition = action_item.execute!(baton)
        if(disposition.failed?)
          disposition.merge(:status => :abort)
        else
          disposition
        end
      end
    end

    def skip_if(reason, &block)
      Modifier.new("Skip if #{reason}") do |action_item, baton|
        if block.call(baton, action_item)
          action_item.skip!(reason)
        else
          action_item.call(baton, action_item)
        end
      end
    end

    def handle_error(error_type, &block)
      Modifier.new("Handle error #{error_type}") do |action_item, baton|
        begin
          action_item.execute!(baton, true)
        rescue error_type => error
          block.call(baton, action_item, error)
        end
      end
    end

    def recover_failure
      Modifier.new("Recover from failure") do |action_item, baton|
        disposition = action_item.execute!(baton)
        if disposition.status == :failed
          yield(baton, action_item, disposition)
        end
      end
    end

    def ignore
      Modifier.new("Ignore failures") do |action_item, baton|
        action_item.ignored=true
        action_item.call(baton, action_item)
      end
    end

    # Filter and optionally modify step disposition
    def filter(&block)
      Modifier.new("Filter disposition") do |action_item, baton|
        block.call(action_item.execute!(baton))
      end
    end

    # TODO Factor this out into its own class, it's a bit big
    # TODO we may want to roll this functionality into the core Checklist. It
    # would be nice if a retried action would actually show up in the log, e.g.:
    # 8. Do some work (Failed; Retrying)
    # 8. Do some work (Succeeded)
    def retry_on_failure(
        times_to_retry=1, time_limit_in_seconds=:none, options={})
      max_tries = times_to_retry.to_i + 1
      clock = options.fetch(:clock) { Time }
      cutoff_time = if time_limit_in_seconds == :none 
                      :none
                    else
                      clock.now + time_limit_in_seconds
                    end
      description = 
        "Retry #{times_to_retry} times"
      unless time_limit_in_seconds == :none
        description << " or #{time_limit_in_seconds} seconds"
      end
      Modifier.new(description) do 
        |action_item, baton|
        tries = 0
        begin
          disposition = action_item.execute!(baton)
          tries += 1
          if disposition.failed? && 
              (cutoff_time != :none) && 
              (clock.now >= cutoff_time)
            break
          end
        end until disposition.succeeded? || tries >= max_tries
        disposition
      end
    end

  end
end
