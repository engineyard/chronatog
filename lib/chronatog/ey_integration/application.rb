module Chronatog
  module EyIntegration
    class Application < Sinatra::Base
      enable :raise_errors
      disable :dump_errors
      disable :show_exceptions

      #################
      # EY Facing API #
      #################

      #TODO: hmac middleware!

      post '/api/1/customers' do
        json_body = request.body.read
#{customer_creation{
        service_account = EY::ServicesAPI::ServiceAccountCreation.from_request(json_body)
        create_params = {
          :name         => service_account.name,
          :api_url      => service_account.url,
          :messages_url => service_account.messages_url,
          :invoices_url => service_account.invoices_url
        }
        customer = Chronatog::Server::Customer.create!(create_params)
#}customer_creation}
#{customer_creation_response{
        response_params = {
          :configuration_required   => false,
          :configuration_url        => "#{base_url}/sso/customers/#{customer.id}",
          :provisioned_services_url => "#{base_url}/api/1/customers/#{customer.id}/schedulers",
          :url                      => "#{base_url}/api/1/customers/#{customer.id}",
          :message                  => EY::ServicesAPI::Message.new(:message_type => "status", 
                                                                    :subject      => "Thanks for signing up for Chronatog!")
        }
        response = EY::ServicesAPI::ServiceAccountResponse.new(response_params)
        content_type :json
        headers 'Location' => response.url
        response.to_hash.to_json
#}customer_creation_response}
      end

      delete "/api/1/customers/:customer_id" do |customer_id|
        customer = Chronatog::Server::Customer.find(customer_id)
        customer.bill!
        customer.destroy
        content_type :json
        {}.to_json
      end

      post "/api/1/customers/:customer_id/schedulers" do |customer_id|
        json_body = request.body.read
        provisioned_service = EY::ServicesAPI::ProvisionedServiceCreation.from_request(json_body)

        customer = Chronatog::Server::Customer.find(customer_id)
        create_params = {
          :environment_name => provisioned_service.environment.name,
          :app_name => provisioned_service.app.name,
          :messages_url => provisioned_service.messages_url
        }
        scheduler = customer.schedulers.create!(create_params)

        response_params = {
          :configuration_required => false,
          :vars     => {
            "CHRONOS_AUTH_USERNAME" => scheduler.auth_username,
            "CHRONOS_AUTH_PASSWORD" => scheduler.auth_password,
            "CHRONOS_SERVICE_URL"   => "#{true_base_url}/chronatogapi/1/jobs",
          },
          :url      => "#{base_url}/api/1/customers/#{customer.id}/schedulers/#{scheduler.id}",
          :message  => EY::ServicesAPI::Message.new(:message_type => "status", 
                                                    :subject      => "Your scheduler has been created and is ready for use!")
        }
        response = EY::ServicesAPI::ProvisionedServiceResponse.new(response_params)
        content_type :json
        headers 'Location' => response.url
        response.to_hash.to_json
      end

      delete "/api/1/customers/:customer_id/schedulers/:job_id" do |customer_id, job_id|
        #TODO: hmac!

        customer = Chronatog::Server::Customer.find(customer_id)
        scheduler = customer.schedulers.find(job_id)
        scheduler.decomission!
        content_type :json
        {}.to_json
      end

      #############################
      # EY facing SSO/Customer UI #
      #############################

      get "/sso/customers/:customer_id" do |customer_id|
        raise "Signature invalid" unless EY::ApiHMAC::SSO.authenticated?(request.url, Chronatog.api_creds.auth_id, Chronatog.api_creds.auth_key)
        @customer = Chronatog::Server::Customer.find(customer_id)
        @redirect_to = params[:ey_return_to_url]
        haml :plans
      end

      get "/sso/customers/:customer_id/schedulers/:scheduler_id" do |customer_id, generator_id|
        #TODO: use a signature verification middleware instead?
        raise "Signature invalid" unless EY::ApiHMAC::SSO.authenticated?(request.url, Chronatog.api_creds.auth_id, Chronatog.api_creds.auth_key)
        @customer = Chronatog::Server::Customer.find(customer_id)
        @generator = @customer.compliment_generators.find(generator_id)
        @redirect_to = params[:ey_return_to_url]
        haml :generators
      end

      ######################
      # Sintra app helpers #
      ######################

      def base_url
        true_base_url + PATHPREFIX
      end

      def true_base_url
        uri = URI.parse(request.url)
        uri.to_s.gsub(uri.request_uri, '')
      end

      def service
        Chronatog::Server::Service.first || (raise "service not setup")
      end

    end
  end
end