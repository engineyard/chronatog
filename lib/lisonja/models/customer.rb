module Lisonja
  class Customer < Model
    belongs_to :service
    has_many :compliment_generators

    def url(base_url)
      "#{base_url}/api/1/customers/#{id}"
    end
    def provisioned_services_url(base_url)
      "#{url(base_url)}/compliment_generators"
    end
    def configuration_url(base_url)
      "#{base_url}/sso/customers/#{id}"
    end
    def singup_message
      "You enabled Lisonja. Well done #{name}!"
    end
    def generate_generator(env_name = nil, messages_url = nil)
      ComplimentGenerator.generate(self, env_name, messages_url)
    end
    def send_compliment(message_type, compliment)
      message = EY::ServicesAPI::Message.new(:message_type => message_type, :subject => compliment)
      Lisonja.connection.send_message(self.messages_url, message)
    end
    def bill!
      self.last_billed_at ||= created_at
      billing_at = Time.now
      #this service costs $0.01 per minute
      total_price = 1 * (billing_at.to_i - last_billed_at.to_i) / 60
      
      puts "total_price so far #{total_price}"
      
      compliment_generators.each do |g|
        usage_seconds = g.get_billable_usage!(billing_at)
        puts "#{usage_seconds} usage for #{g.inspect}"
        #compliment generators costs $0.02 per second
        usage_price = usage_seconds * 2
        total_price += usage_price

        puts "total_price so far #{total_price}"
      end
      if total_price > 0
        line_item_description = "For service from #{last_billed_at} to #{billing_at}, "+
                                  "includes #{compliment_generators.size} compliment generators."

        invoice = EY::ServicesAPI::Invoice.new(
          :total_amount_cents => total_price,
          :line_item_description => line_item_description)
        Lisonja.connection.send_invoice(invoices_url, invoice)

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
      compliment_generators.destroy_all
    end
  end
end