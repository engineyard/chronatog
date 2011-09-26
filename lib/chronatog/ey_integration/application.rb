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
#{customer_creation{
        #parse the request
        service_account = EY::ServicesAPI::ServiceAccountCreation.from_request(request.body.read)
        #create a new customer
        customer = service.customers.create!( :name         => service_account.name,
                                              :api_url      => service_account.url,
                                              :messages_url => service_account.messages_url,
                                              :invoices_url => service_account.invoices_url)
#}customer_creation}
#{customer_creation_response{
        #create a response hash with information about the customer
        response_hash = service_account.creation_response_hash do |presenter|
          presenter.configuration_required = false
          presenter.configuration_url = customer.configuration_url(base_url)
          presenter.provisioned_services_url = customer.provisioned_services_url(base_url)
          presenter.url = customer.url(base_url)
          presenter.message = EY::ServicesAPI::Message.new(:message_type => "status", :subject => customer.singup_message)
        end
        #Set the Content-Type to JSON
        content_type :json
        #Set the Location header for extra REST (has the same value as response_hash["service_account"]["url"] )
        headers 'Location' => customer.url(base_url)
        #render the response_hash as json
        response_hash.to_json
#}customer_creation_response}
      end

      delete "/api/1/customers/:customer_id" do |customer_id|
        #TODO: hmac!

        @customer = Chronatog::Server::Customer.find(customer_id)
        @customer.cancel!
        @customer.destroy
        content_type :json
        {}.to_json
      end

      post "/api/1/customers/:customer_id/schedulers" do |customer_id|
        #TODO: hmac!

        #parse the request
        provisioned_service = EY::ServicesAPI::ProvisionedServiceCreation.from_request(request.body.read)

        #do local persistence
        customer = Chronatog::Server::Customer.find(customer_id)
        scheduler = customer.schedulers.create!(
        :environment_name => provisioned_service.environment.name,
        :app_name => provisioned_service.app.name,
        :messages_url => provisioned_service.messages_url
        )
        # job = customer.add_scheduled_job(provisioned_service.environment.name, provisioned_service.messages_url)

        #sinatra stuff
        content_type :json
        headers 'Location' => scheduler.url(base_url)

        #response with json about self
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

      # template :plans do
      #   <<-EOT
      #   %h2 Select a plan
      #   %form{:action=> "/sso/customers/"+@customer.id.to_s+"/choose_plan", :method=>'POST'}
      #   %input{:name => "ey_return_to_url", :value => @redirect_to, :type => "hidden"}
      #   %select{:name => 'plan_type'}
      #   %option{:value => 'baller plan'} baller plan
      #   %input{:value=>'Continue', :type=>'submit'}
      #   EOT
      # end

      get "/sso/customers/:customer_id/schedulers/:scheduler_id" do |customer_id, generator_id|
        #TODO: use a signature verification middleware instead?
        raise "Signature invalid" unless EY::ApiHMAC::SSO.authenticated?(request.url, Chronatog.api_creds.auth_id, Chronatog.api_creds.auth_key)
        @customer = Chronatog::Server::Customer.find(customer_id)
        @generator = @customer.compliment_generators.find(generator_id)
        @redirect_to = params[:ey_return_to_url]
        haml :generators
      end

      # template :generators do
      #   <<-EOT
      #   %h2 Select a generator type
      #   %form{:action=> "/sso/customers/"+@customer.id.to_s+"/generators/"+@generator.id.to_s+"/choose_type", :method=>'POST'}
      #   %input{:name => "ey_return_to_url", :value => @redirect_to, :type => "hidden"}
      #   %select{:name => 'generator_type'}
      #   %option{:value => 'best compliments'} best compliments
      #   %input{:value=>'Continue', :type=>'submit'}
      #   EOT
      # end


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