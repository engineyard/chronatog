module Chronatog
  module EyIntegration
    module CustomerExtensions

      def self.included(base)
        base.class_eval do
          belongs_to :service
          after_initialize do
            self.plan_type ||= 'freemium'
          end
        end
      end

      def plans
        [['freemium', "Freemium"], ['awesome', "OMG IT'S SO AWESOME"]]
      end

      def current_plan_name
        plans.detect{|plan| plan[0] == plan_type }[1]
      end

#{customer_billing{
      def bill!
        #don't bill free customers
        return if plan_type == "freemium"

        self.last_billed_at ||= created_at
        billing_at = Time.now
        #having the awesome service active costs $0.02 per day
        total_price = 2 * (billing_at.to_i - last_billed_at.to_i) / 60 / 60 / 24

        total_jobs_ran = 0
        schedulers.each do |schedule|
          #add $0.05 for every time we called a job
          usage_price = 5 * schedule.usage_calls
          total_jobs_ran += schedule.usage_calls
          schedule.usage_calls = 0
          schedule.save
          total_price += usage_price
        end
        if total_price > 0
          line_item_description = [
            "For service from #{last_billed_at.strftime('%Y/%m/%d')}",
            "to #{billing_at.strftime('%Y/%m/%d')}",
            "includes #{schedulers.size} schedulers", 
            "and #{total_jobs_ran} jobs run.",
          ].join(" ")

          invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => total_price,
                                                 :line_item_description => line_item_description)
          Chronatog::EyIntegration.connection.send_invoice(self.invoices_url, invoice)

          self.last_billed_at = billing_at
          save!
        end
      end
#}customer_billing}

    end
  end
end