module Chronatog
  module EyIntegration
    class Application < Sinatra::Base
      enable :raise_errors
      disable :dump_errors
      disable :show_exceptions

      post '/api/1/customers' do
        json_body = request.body.read
        service_account = EY::ServicesAPI::ServiceAccountCreation.from_request(json_body)
        customer = Chronatog::Server::Customer.create!( :name         => service_account.name,
                                                        :api_url      => service_account.url,
                                                        :messages_url => service_account.messages_url,
                                                        :invoices_url => service_account.invoices_url)

        response = EY::ServicesAPI::ServiceAccountResponse.new(:configuration_required   => false,
                                                               :configuration_url        => "#{base_url}/sso/customers/#{customer.id}",
                                                               :provisioned_services_url => "#{base_url}/api/1/customers/#{customer.id}/schedulers",
                                                               :url                      => "#{base_url}/api/1/customers/#{customer.id}",
                                                               :message                  => EY::ServicesAPI::Message.new(:message_type => "status", 
                                                                                                                         :subject      => "Thanks for signing up to Chronatog!"))
        content_type :json
        headers 'Location' => customer.url(base_url)
        response.to_json
      end

      delete "/api/1/customers/:customer_id" do |customer_id|
        customer = Chronatog::Server::Customer.find(customer_id)
        customer.send_final_invoice_to_engineyard!
        customer.destroy
        content_type :json
        {}.to_json
      end

      post "/api/1/customers/:customer_id/schedulers" do |customer_id|
        json_body = request.body.read
        provisioned_service = EY::ServicesAPI::ProvisionedServiceCreation.from_request(json_body)

        customer = Chronatog::Server::Customer.find(customer_id)
        scheduler = customer.schedulers.create!(:environment_name => provisioned_service.environment.name,
                                                :app_name         => provisioned_service.app.name,
                                                :messages_url     => provisioned_service.messages_url)

        content_type :json
        headers 'Location' => scheduler.url(base_url)

        EyAdapter.services[:chronatog][:auth_username]
        EyAdapter.services["CHRONATOG_AUTH_USERNAME"]

        response = EY::ServicesAPI::ProvisionedServiceResponse.new(:configuration_required => false,
                                                                   :vars => {
                                                                     :auth_username => scheduler.auth_username,
                                                                     :auth_password => scheduler.auth_password,
                                                                     :service_url   => "#{true_base_url}/chronatogapi/1/jobs",
                                                                   },
                                                                   :url => scheduler.url(base_url),
                                                                   :message => EY::ServicesAPI::Message.new(:message_type => "status", :subject => "Your scheduler has been created and is ready for use!"))
        
        response_hash = provisioned_service.creation_response_hash do |presenter|
          presenter.configuration_required = false
          presenter.vars = {
            "CHRONOS_AUTH_USERNAME"  => scheduler.auth_username,
            "CHRONOS_AUTH_PASSWORD" => scheduler.auth_password,
            "CHRONOS_SERVICE_URL" => "#{true_base_url}/chronatogapi/1/jobs",
          }
          presenter.url = scheduler.url(base_url)
          presenter.message = EY::ServicesAPI::Message.new(:message_type => "status", :subject => scheduler.created_message)
        end

        response_hash.to_json
      end

      delete "/api/1/customers/:customer_id/schedulers/:job_id" do |customer_id, job_id|
        customer = Chronatog::Server::Customer.find(customer_id)
        scheduler = customer.schedulers.find(job_id)
        scheduler.decomission!
        content_type :json
        {}.to_json
      end

      get "/sso/customers/:customer_id" do |customer_id|
        raise "Signature invalid" unless EY::ApiHMAC::SSO.authenticated?(request.url, Chronatog.api_creds.auth_id, Chronatog.api_creds.auth_key)
        @customer = Chronatog::Server::Customer.find(customer_id)
        @redirect_to = params[:ey_return_to_url]
        haml :plans
      end

      get "/sso/customers/:customer_id/schedulers/:scheduler_id" do |customer_id, generator_id|
        raise "Signature invalid" unless EY::ApiHMAC::SSO.authenticated?(request.url, Chronatog.api_creds.auth_id, Chronatog.api_creds.auth_key)
        @customer = Chronatog::Server::Customer.find(customer_id)
        @generator = @customer.compliment_generators.find(generator_id)
        @redirect_to = params[:ey_return_to_url]
        haml :generators
      end

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