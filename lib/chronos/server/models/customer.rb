module Chronos::Server
  class Customer < Model
    belongs_to :service
    has_many :schedulers

    def url(base_url)
      "#{base_url}/api/1/customers/#{id}"
    end

    def provisioned_services_url(base_url)
      "#{url(base_url)}/schedulers"
    end

    def configuration_url(base_url)
      "#{base_url}/sso/customers/#{id}"
    end

    def singup_message
      "You enabled Chronos. Well done #{name}!"
    end

    def create_scheduled_job(job)
      Scheduler.add(self, env_name, job)
    end

    def bill!
      self.last_billed_at ||= created_at
      billing_at = Time.now
      #this service costs $0.01 per minute
      total_price = 1 * (billing_at.to_i - last_billed_at.to_i) / 60

      puts "total_price so far #{total_price}"

      schedulers.each do |schedule|
        usage_seconds = schedule.get_billable_usage!(billing_at)
        puts "#{usage_seconds} usage for #{schedule.inspect}"
        #schedulers costs $0.02 per second
        usage_price = usage_seconds * 2
        total_price += usage_price

        puts "total_price so far #{total_price}"
      end
      if total_price > 0
        line_item_description = "For service from #{last_billed_at} to #{billing_at}, "+
                                  "includes #{schedulers.size} schedulers."

        invoice = EY::ServicesAPI::Invoice.new(
          :total_amount_cents => total_price,
          :line_item_description => line_item_description)
        Chronos.connection.send_invoice(invoices_url, invoice)

        self.last_billed_at = billing_at
        save!

        #return info about charges made
        [total_price, line_item_description]
      else
        #return no charge made
        nil
      end
    end

    def cancel!
      bill!
      schedulers.destroy_all
    end
  end
end
