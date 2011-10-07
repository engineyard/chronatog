require 'chronatog/ey_integration/controllers/base'

module Chronatog
  module EyIntegration
    module Controller
      class SSO < Base

        #############################
        # EY facing SSO/Customer UI #
        #############################

        get "/customers/:customer_id" do |customer_id|
          raise "Signature invalid" unless EY::ApiHMAC::SSO.authenticated?(request.url, 
                                                                           Chronatog::EyIntegration.api_creds.auth_id, 
                                                                           Chronatog::EyIntegration.api_creds.auth_key)
          @customer = Chronatog::Server::Customer.find(customer_id)
          @redirect_to = params[:ey_return_to_url]
          "TODO: you have SSO'd in to customer #{@customer.inspect}"
        end

        get "/customers/:customer_id/schedulers/:scheduler_id" do |customer_id, scheduler_id|
          raise "Signature invalid" unless EY::ApiHMAC::SSO.authenticated?(request.url, 
                                                                           Chronatog::EyIntegration.api_creds.auth_id, 
                                                                           Chronatog::EyIntegration.api_creds.auth_key)
          @customer = Chronatog::Server::Customer.find(customer_id)
          @redirect_to = params[:ey_return_to_url]
          "TODO: you have SSO'd in to customer #{@customer.inspect} for scheduler_id"
        end

      end
    end
  end
end