require 'rack/client'
require 'json'
require 'ey_api_hmac'

module EY
  module ServicesAPI
    class Connection < EY::ApiHMAC::BaseConnection

      def default_user_agent
        "EY-ServicesAPI/#{VERSION}"
      end

      def register_service(registration_url, params)
        post(registration_url, :service => params) do |json_body, response_location|
          service = Service.new(params)
          service.connection = self
          service.url = response_location
          service
        end
      end

      def get_service(url)
        response = get(url) do |json_body|
          service = Service.new(json_body["service"])
          service.connection = self
          service.url = url
          service
        end
      end

      def update_service(url, params)
        put(url, :service => params)
      end

      def destroy_service(url)
        delete(url)
      end

      def send_message(url, message)
        post(url, :message => message.to_hash)
      end

      def send_invoice(invoices_url, invoice)
        post(invoices_url, :invoice => invoice.to_hash)
      end

    end
  end
end