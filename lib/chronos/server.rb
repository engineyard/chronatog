#TODO: remove this line when chronos is release as gem
$LOAD_PATH << File.expand_path('../', __FILE__)

require 'sinatra'
require 'json'
require 'yaml'
require 'haml'
require 'ey_api_hmac'
require 'ey_services_api'
require 'chronos/server/models/model'
require 'chronos/server/models/schema'
#TODO: just traverse the directory?
%w( creds service customer scheduler ).each do |model_name|
  require "chronos/server/models/#{model_name}"
end

module Chronos::Server

  class << self
    attr_accessor :scheduler
  end

  class Application < Sinatra::Base
    enable :raise_errors
    disable :dump_errors
    disable :show_exceptions

    ########################
    # Public Facing Web UI #
    ########################

    get "/" do
      "This is Chronos, an example service."
    end

    get "/terms" do
      "Agree to our terms, or else..."
    end

    #################
    # EY Facing API #
    #################

    post '/api/1/customers' do
      #parse the request
      service_account = EY::ServicesAPI::ServiceAccountCreation.from_request(request.body.read)

      service = Service.first || (raise "service not setup")
      customer = service.customers.create!(
        :name => service_account.name,
        :api_url => service_account.url,
        :messages_url => service_account.messages_url,
        :invoices_url => service_account.invoices_url)

      #sinatra stuff
      content_type :json
      headers 'Location' => customer.url(base_url)

      #response with json about self
      response_hash = service_account.creation_response_hash do |presenter|
        presenter.configuration_required = false
        presenter.configuration_url = customer.configuration_url(base_url)
        presenter.provisioned_services_url = customer.provisioned_services_url(base_url)
        presenter.url = customer.url(base_url)
        presenter.message = EY::ServicesAPI::Message.new(:message_type => "status", :subject => customer.singup_message)
      end

      response_hash.to_json
    end

    delete "/api/1/customers/:customer_id" do |customer_id|
      @customer = Customer.find(customer_id)
      @customer.cancel!
      @customer.destroy
      content_type :json
      {}.to_json
    end

    post "/api/1/customers/:customer_id/schedulers" do |customer_id|
      #parse the request
      provisioned_service = EY::ServicesAPI::ProvisionedServiceCreation.from_request(request.body.read)

      #do local persistence
      customer = Customer.find(customer_id)
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
          "CHRONOS_AUTH_ID"  => scheduler.client_auth_id,
          "CHRONOS_AUTH_KEY" => scheduler.client_auth_key
        }
        presenter.url = scheduler.url(base_url)
        presenter.message = EY::ServicesAPI::Message.new(:message_type => "status", :subject => scheduler.created_message)
      end

      response_hash.to_json
    end

    delete "/api/1/customers/:customer_id/schedulers/:job_id" do |customer_id, job_id|
      customer = Customer.find(customer_id)
      scheduler = customer.schedulers.find(job_id)
      scheduler.decomission!
      content_type :json
      {}.to_json
    end

    #############################
    # EY facing SSO/Customer UI #
    #############################

    get "/sso/customers/:customer_id" do |customer_id|
      raise "Signature invalid" unless EY::ApiHMAC::SSO.authenticated?(request.url, Chronos.api_creds.auth_id, Chronos.api_creds.auth_key)
      @customer = Chronos::Customer.find(customer_id)
      @redirect_to = params[:ey_return_to_url]
      haml :plans
    end

    template :plans do
<<-EOT
%h2 Select a plan
%form{:action=> "/sso/customers/"+@customer.id.to_s+"/choose_plan", :method=>'POST'}
  %input{:name => "ey_return_to_url", :value => @redirect_to, :type => "hidden"}
  %select{:name => 'plan_type'}
    %option{:value => 'baller plan'} baller plan
  %input{:value=>'Continue', :type=>'submit'}
EOT
    end

    get "/sso/customers/:customer_id/schedulers/:scheduler_id" do |customer_id, generator_id|
      #TODO: use a signature verification middleware instead?
      raise "Signature invalid" unless EY::ApiHMAC::SSO.authenticated?(request.url, Chronos.api_creds.auth_id, Chronos.api_creds.auth_key)
      @customer = Chronos::Customer.find(customer_id)
      @generator = @customer.compliment_generators.find(generator_id)
      @redirect_to = params[:ey_return_to_url]
      haml :generators
    end

    template :generators do
<<-EOT
%h2 Select a generator type
%form{:action=> "/sso/customers/"+@customer.id.to_s+"/generators/"+@generator.id.to_s+"/choose_type", :method=>'POST'}
  %input{:name => "ey_return_to_url", :value => @redirect_to, :type => "hidden"}
  %select{:name => 'generator_type'}
    %option{:value => 'best compliments'} best compliments
  %input{:value=>'Continue', :type=>'submit'}
EOT
    end

    ######################
    # Sintra app helpers #
    ######################

    def base_url
      uri = URI.parse(request.url)
      uri.to_s.gsub(uri.request_uri, '')
    end

  end

  ##################################
  # DB and EY API Connection setup #
  ##################################

  def self.connection
    EY::ServicesAPI.connection
  end

  def self.ensure_tmp_dir
    require 'fileutils'
    FileUtils.mkdir_p(File.expand_path("../../../tmp/", __FILE__))
    FileUtils.mkdir_p(File.expand_path("../../../config/", __FILE__))
  end

  def self.setup!
    ensure_tmp_dir
    Schema.setup!
    Scheduler.setup!
    if api_creds
      EY::ServicesAPI.setup!(:auth_id => api_creds.auth_id, :auth_key => api_creds.auth_key)
    end
  end

  def self.teardown!
    ensure_tmp_dir
    Scheduler.teardown!
    Schema.teardown!
  end

  def self.reset!
    teardown!
    setup!
  end

  ####################################
  # Registering this service with EY #
  ####################################

  #TODO: make a rake task for registering

  def self.register_service(service_registration_url, base_url)
    #TODO: raise if we don't have any credentials
    create_service("Chronos", service_registration_params(base_url), service_registration_url)
  end

  def self.service_registration_params(base_url)
    {
      :name => "Chronos",
      :description => "Web cron as a service.",
      :service_accounts_url =>     "#{base_url}/api/1/customers",
      :home_url =>                 "#{base_url}/",
      :terms_and_conditions_url => "#{base_url}/terms",
      :vars => ["CHRONOS_AUTH_ID", "CHRONOS_AUTH_KEY"]
    }
  end

  def self.create_service(service_name, registration_params, service_registration_url)
    service = Service.create!(:name => service_name, :state => 'unregistered')
    remote_service = connection.register_service(service_registration_url, registration_params)
    service.url = remote_service.url
    service.state = "registered"
    service.save!
    service
  end

  #################################
  # Credentials for talking to EY #
  #################################

  #TODO: make a rake task for saving credentials (takes args)

  def self.api_creds
    @creds ||= Credentials.load
  end

  def self.save_creds(auth_id, auth_key)
    Credentials.write!(:auth_id => auth_id, :auth_key => auth_key)
  end

  class Credentials < Struct.new(:auth_id, :auth_key)
    CONFIG_PATH = File.expand_path('../../../config/credentials.yml', __FILE__)
    def self.load
      if File.exists?(CONFIG_PATH)
        creds = YAML.load_file(CONFIG_PATH)
        Credentials.new(creds[:auth_id], creds[:auth_key])
      end
    end
    def self.write!(creds)
      File.open(CONFIG_PATH, "w") do |fp|
        fp.write(creds.to_yaml)
      end
    end
  end
end
