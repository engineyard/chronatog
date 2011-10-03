module Chronatog
  module EyIntegration
    module SchedulerExtensions

      def get_billable_usage!(at_time)
        if decomissioned_at && (decomissioned_at < at_time)
          at_time = decomissioned_at
        end
        self.last_billed_at ||= created_at
        if decomissioned_at && (last_billed_at >= decomissioned_at)
          return 0
        end
        to_return = (at_time.to_i - last_billed_at.to_i)
        self.last_billed_at = at_time
        save!
        to_return
      end

      def decomission!
        self.decomissioned_at = Time.now
        save!
      end

    end
  end
end