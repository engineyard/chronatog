module Lisonja
  class ComplimentGenerator < Model
    belongs_to :customer
    
    def url
      "#{ENV["URL_FOR_LISONJA"]}/api/1/customers/#{customer_id}/compliment_generators/#{id}"
    end
    def configuration_url
      "#{ENV["URL_FOR_LISONJA"]}/sso/customers/#{customer_id}/generators/#{id}"
    end
    def created_message
      "Compliment Generator Generated!"
    end
    def generate_compliment!
      Lisonja.compliment_source.run! #+ " for #{name}"
    end
    def generate_and_send_compliment(message_type)
      compliment = generate_compliment!
      message = EY::ServicesAPI::Message.new(:message_type => message_type, :subject => compliment)
      Lisonja.connection.send_message(self.messages_url, message)
      compliment
    end
    def self.generate(customer, environment_name, messages_url)
      customer.compliment_generators.create!(
        :environment_name => environment_name,
        :api_key => rand.to_s[2,10], 
        :messages_url => messages_url,
        :generator_type => 'default'
      )
    end
    def get_billable_usage!(at_time)
      if decomissioned_at < at_time
        at_time = decomissioned_at
      end
      self.last_billed_at ||= created_at
      if last_billed_at >= decomissioned_at
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

    def service_kind
      service.kind
    end
    
    def service
      customer.service
    end
  end
end