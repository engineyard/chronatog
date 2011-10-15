require 'chronatog/ey_integration/controllers/base'

module Chronatog
  module EyIntegration
    module Controller
      class API < Base

#{hmac_middleware{
        use EY::ApiHMAC::ApiAuth::LookupServer do |env, auth_id|
          EyIntegration.api_creds && (EyIntegration.api_creds.auth_id == auth_id) && EyIntegration.api_creds.auth_key
        end
#}hmac_middleware}

        #################
        # EY Facing API #
        #################

        post '/customers' do
#{customer_creation{
          request_body = request.body.read
          service_account = EY::ServicesAPI::ServiceAccountCreation.from_request(request_body)
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
            :configuration_url        => "#{sso_base_url}/customers/#{customer.id}",
            :provisioned_services_url => "#{api_base_url}/customers/#{customer.id}/schedulers",
            :url                      => "#{api_base_url}/customers/#{customer.id}",
            :message                  => EY::ServicesAPI::Message.new(:message_type => "status", 
                                                                      :subject      => "Thanks for signing up for Chronatog!")
          }
          response = EY::ServicesAPI::ServiceAccountResponse.new(response_params)
          content_type :json
          headers 'Location' => response.url
          response.to_hash.to_json
#}customer_creation_response}
        end

        delete "/customers/:customer_id" do |customer_id|
#{customer_cancellation{
          customer = Chronatog::Server::Customer.find(customer_id)
          customer.bill!
          customer.destroy
          content_type :json
          {}.to_json
#}customer_cancellation}
        end

        post "/customers/:customer_id/schedulers" do |customer_id|
#{service_provisioning{
          request_body = request.body.read
          provisioned_service = EY::ServicesAPI::ProvisionedServiceCreation.from_request(request_body)

          customer = Chronatog::Server::Customer.find(customer_id)
          create_params = {
            :environment_name => provisioned_service.environment.name,
            :app_name => provisioned_service.app.name,
            :messages_url => provisioned_service.messages_url,
            :usage_calls => 0
          }
          scheduler = customer.schedulers.create!(create_params)
#}service_provisioning}
#{service_provisioning_response{
          response_params = {
            :configuration_required => false,
            :vars     => {
              "CHRONOS_AUTH_USERNAME" => scheduler.auth_username,
              "CHRONOS_AUTH_PASSWORD" => scheduler.auth_password,
              "CHRONOS_SERVICE_URL"   => "#{true_base_url}/chronatogapi/1/jobs",
            },
            :url      => "#{api_base_url}/customers/#{customer.id}/schedulers/#{scheduler.id}",
            :message  => EY::ServicesAPI::Message.new(:message_type => "status", 
                                                      :subject      => "Your scheduler has been created and is ready for use!")
          }
          response = EY::ServicesAPI::ProvisionedServiceResponse.new(response_params)
          content_type :json
          headers 'Location' => response.url
          response.to_hash.to_json
#}service_provisioning_response}
        end

        delete "/customers/:customer_id/schedulers/:job_id" do |customer_id, job_id|
          customer = Chronatog::Server::Customer.find(customer_id)
          scheduler = customer.schedulers.find(job_id)
          scheduler.decomission!
          content_type :json
          {}.to_json
        end

      end
    end
  end
end