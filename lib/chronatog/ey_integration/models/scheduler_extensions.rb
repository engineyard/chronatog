module Chronatog
  module EyIntegration
    module SchedulerExtensions

      def decomission!
        self.decomissioned_at = Time.now
        save!
      end

      #TODO: make sure you can't add/remove jobs to decomissioned schedulers

    end
  end
end