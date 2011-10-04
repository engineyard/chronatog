require 'chronatog/ey_integration/controllers/base'

module Chronatog
  module EyIntegration
    module Controller
      class SSO < Base

        #############################
        # EY facing SSO/Customer UI #
        #############################

        get "/customers/:customer_id" do |customer_id|
          raise "Signature invalid" unless EY::ApiHMAC::SSO.authenticated?(request.url, Chronatog.api_creds.auth_id, Chronatog.api_creds.auth_key)
          @customer = Chronatog::Server::Customer.find(customer_id)
          @redirect_to = params[:ey_return_to_url]
          haml :plans
        end

        get "/customers/:customer_id/schedulers/:scheduler_id" do |customer_id, generator_id|
          #TODO: use a signature verification middleware instead?
          raise "Signature invalid" unless EY::ApiHMAC::SSO.authenticated?(request.url, Chronatog.api_creds.auth_id, Chronatog.api_creds.auth_key)
          @customer = Chronatog::Server::Customer.find(customer_id)
          @generator = @customer.compliment_generators.find(generator_id)
          @redirect_to = params[:ey_return_to_url]
          haml :generators
        end
        
      end
    end
  end
end