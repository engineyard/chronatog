module Chronos
  module EyIntegration
    module SchedulerExtensions

      def self.setup!
        # @scheduler ||= Rufus::Scheduler.start_new
        # all.each do |scheduled_job|
        #   scheduled_job.schedule
        # end
      end

      def self.teardown!
        # @scheduler.stop
      end

      def self.add(customer, env_name, job)
        # new_job_cheduled = customer.schedulers.create!(
        #   :environment_name => env_name,
        #   :api_key => rand.to_s[2,10],
        #   :messages_url => messages_url,
        #   :job => job
        # )
        # new_job_scheduled.schedule
      end

      def schedule
        # Scheduler.scheduler.cron job[:cron], :tag => id do
        #   Net::HTTP.get(URI.parse(job[:uri]))
        # end
        # self
      end

      def url(base_url)
        "#{base_url}/api/1/customers/#{customer_id}/schedulers/#{id}"
      end

      def configuration_url(base_url)
        "#{base_url}/sso/customers/#{customer_id}/generators/#{id}"
      end

      def created_message
        "Scheduler created!"
      end

      def generate_and_send_compliment(message_type)
        compliment = generate_compliment!
        message = EY::ServicesAPI::Message.new(:message_type => message_type, :subject => compliment)
        Chronos.connection.send_message(self.messages_url, message)
        compliment
      end

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
        # Scheduler.scheduler.find_by_tag(id).first.unschedule
        save!
      end

      def service_kind
        service.kind
      end

      def service
        customer.service
      end

    end
  end
end