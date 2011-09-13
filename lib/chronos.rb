#TODO: remove this line when chronos is release as gem
$LOAD_PATH << File.expand_path('../', __FILE__)

require 'sinatra'
require 'json'
require 'yaml'
require 'haml'
require 'ey_api_hmac'
require 'ey_services_api'
require 'chronos/models/model'
require 'chronos/models/schema'
%w( creds service customer scheduler ).each do |model_name|
  require "chronos/models/#{model_name}"
end

module Chronos
  class << self
    attr_accessor :scheduler
  end

  class Application < Sinatra::Base
    enable :raise_errors
    disable :dump_errors
    disable :show_exceptions

    get "/" do
      to_output = ""
      if !Chronos.regular_service
        to_output += <<-EOT
          <div id="basic">
          Register the Regular Chronos service:<br/>
            <form action="/register" method="POST">
              <label for="service_registration_url">Service Registration API URL</label>
              <input id="service_registration_url" name="service_registration_url" type="text" />
              <input value="Register" type="submit" />
            </form>
          </div>
        EOT
      else
        to_output += "Regular Chronos registered as #{Chronos.regular_service.url} <br/>"
      end
      to_output += "<a href='/cron'>run billing cron</a> <br/>"
      to_output += "current customer info: <pre>#{Chronos::Customer.all.to_yaml}</pre>"
      #to_output += "current generator info: <pre>#{Chronos::ComplimentGenerator.all.to_yaml}</pre>"
      Chronos::Customer.all.each do |customer|
        to_output += "<a href='/customers/#{customer.id}'>#{customer.name}</a>"
      end
      to_output
    end

    get "/bill" do
      invoices_billed = []
      Chronos::Customer.all.each do |customer|
        if billed_info = customer.bill!
          invoices_billed << billed_info
        end
      end
      "Just billed: #{invoices_billed.to_yaml}"
    end

    post "/register" do
      Chronos.register_service(params[:service_registration_url], base_url)
      redirect "/"
    end

    get "/terms" do
      "Agree to our terms, or else..."
    end

    template :customer do
<<-EOT
%h1= @customer.name + " (" + @customer.id.to_s + ") "
- if @recent_message
  %strong Sent:
  = @recent_message
%form{:action=>"/customers/"+@customer.id.to_s+"/generate_compliment", :method=>'POST'}
  %select{:name => 'message_type'}
    %option{:value => 'alert'} Alert
    %option{:value => 'notification'} Notification
    %option{:value => 'status'} Status
  %input{:value=>'Compliment the Customer', :type=>'submit'}
%h2 Generators:
- @customer.compliment_generators.each do |compliment_generator|
  %a{:href => '/customers/'+@customer.id.to_s+'/generators/'+compliment_generator.id.to_s}
    = compliment_generator.environment_name
EOT
    end

    get "/customers/:customer_id" do |customer_id|
      @customer = Chronos::Customer.find(customer_id)
      @recent_message = params[:message]
      if @customer
        haml :customer
      else
        halt 404, 'nonesuch customer'
      end
    end

    post "/customers/:customer_id/schedulers" do |customer_id|
      @customer = Chronos::Customer.find(customer_id)
      message = EY::ServicesAPI::Message.new(:message_type => params[:message_type], :subject => generated)
      Chronos.connection.send_message(@customer.messages_url, message)
      redirect "/customers/#{@customer.id}?message=#{URI.escape(generated)}"
    end

    post "/api/1/customers/:customer_id/schedulers" do |customer_id|
      #parse the request
      provisioned_service = EY::ServicesAPI::ProvisionedServiceCreation.from_request(request.body.read)

      #do local persistence
      customer = Chronos::Customer.find(customer_id)
      job = customer.add_scheduled_job(provisioned_service.environment.name, provisioned_service.messages_url)

      #sinatra stuff
      content_type :json
      headers 'Location' => job.url(base_url)

      #response with json about self
      response_hash = provisioned_service.creation_response_hash do |presenter|
        presenter.configuration_required = false
        presenter.vars = {
          "CHRONOS_AUTH_ID"  => "",
          "CHRONOS_AUTH_KEY" => ""
        }
        presenter.url = job.url(base_url)
        presenter.message = EY::ServicesAPI::Message.new(:message_type => "status", :subject => job.created_message)
      end

      response_hash.to_json
    end

    delete "/api/1/customers/:customer_id/schedulers/:job_id" do |customer_id, job_id|
      customer = Chronos::Customer.find(customer_id)
      scheduler = customer.schedulers.find(job_id)
      scheduler.decomission!
      content_type :json
      {}.to_json
    end

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


    delete "/api/1/customers/:customer_id" do |customer_id|
      @customer = Chronos::Customer.find(customer_id)
      @customer.cancel!
      @customer.destroy
      content_type :json
      {}.to_json
    end

    def base_url
      uri = URI.parse(request.url)
      uri.to_s.gsub(uri.request_uri, '')
    end

  end

  def self.connection
    @connection ||= EY::ServicesAPI::Connection.new(Chronos.api_creds.auth_id, Chronos.api_creds.auth_key, "Chronos")
  end

  def self.ensure_tmp_dir
    require 'fileutils'
    FileUtils.mkdir_p(File.expand_path("../../tmp/", __FILE__))
  end

  def self.setup!
    ensure_tmp_dir
    Schema.setup!
    Scheduler.setup!
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

  def self.api_creds
    @creds ||= Credentials.load
  end

  def self.regular_service
    Chronos::Service.where(:kind => "regular").first
  end

  def self.save_creds(auth_id, auth_key)
    raise "We already have creds!" if api_creds
    Chronos::Creds.create!(:auth_id => auth_id, :auth_key => auth_key)
  end

  def self.register_service(service_registration_url, base_url)
    create_service("Chronos", service_registration_params(base_url), service_registration_url)
  end

  def self.service_registration_params(base_url)
    {
      :name => "Chronos",
      :description => "Web cron as a service.",
      :service_accounts_url =>     "#{base_url}/api/1/customers/regular",
      :home_url =>                 "#{base_url}/",
      :terms_and_conditions_url => "#{base_url}/terms",
      :vars => ["CHRONOS_AUTH_ID", "CHRONOS_AUTH_KEY"]
    }
  end

  def self.create_service(service_name, registration_params, service_registration_url)
    service = Chronos::Service.create!(:name => service_name, :state => 'unregistered')
    remote_service = Chronos.connection.register_service(service_registration_url, registration_params)
    service.url = remote_service.url
    service.state = "registered"
    service.save!
  end

  class Credentials < Struct.new(:auth_id, :auth_key)
    def self.load
      creds = YAML.load_file(File.expand_path('../../config/credentials.yml', __FILE__))
      Creds.new(:auth_id => creds['CHRONOS_PARTNER_AUTH_ID'], :auth_key => creds['CHRONOS_PARTNER_AUTH_KEY'])
    end
  end
end
