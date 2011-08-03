require 'sinatra'
require 'json'
require 'yaml'
require 'haml'
require 'ey_api_hmac'
require 'ey_services_api'
require 'lisonja/models/model'
%w( creds service customer compliment_generator ).each do |model_name|
  require "lisonja/models/#{model_name}"
end

module Lisonja
  class << self
    attr_accessor :compliment_source
  end

  class Application < Sinatra::Base
    enable :raise_errors
    disable :dump_errors
    disable :show_exceptions

    get "/" do
      to_output = ""
      if !Lisonja.api_creds
        to_output += <<-EOT
          <div id="creds">
          Save API Creds:<br/>
            <form action="/savecreds" method="POST">
              <label for="auth_id">Auth ID</label>
              <input id="auth_id" name="auth_id" type="text" />
              <label for="auth_key">Auth Key</label>
              <input id="auth_key" name="auth_key" type="text" />
              <input value="Save Creds" type="submit" />
            </form>
          </div>
        EOT
      end
      if !Lisonja.regular_service
        to_output += <<-EOT
          <div id="basic">
          Register the Regular Lisonja service:<br/>
            <form action="/register" method="POST">
              <label for="service_registration_url">Service Registration API URL</label>
              <input id="service_registration_url" name="service_registration_url" type="text" />
              <input value="Register" type="submit" />
            </form>
          </div>
        EOT
      else
        to_output += "Regular lisonja registered as #{Lisonja.regular_service.url} <br/>"
      end
      if !Lisonja.fancy_service
        to_output += <<-EOT
          <div id="configured">
          Register the Highly Configured Fancy Lisonja service:<br/>
            <form action="/registerfancy" method="POST">
              <label for="service_registration_url">Service Registration API URL</label>
              <input id="service_registration_url" name="service_registration_url" type="text" />
              <input value="Register" type="submit" />
            </form>
          </div>
        EOT
      else
        to_output += "Fancy lisonja registered as #{Lisonja.fancy_service.url} <br/>"
      end
      to_output += "<a href='/cron'>run billing cron</a> <br/>"
      to_output += "current customer info: <pre>#{Lisonja::Customer.all.to_yaml}</pre>"
      to_output += "current generator info: <pre>#{Lisonja::ComplimentGenerator.all.to_yaml}</pre>"
      Lisonja::Customer.all.each do |customer|
        to_output += "<a href='/customers/#{customer.id}'>#{customer.name}</a>"
      end
      to_output
    end

    get '/reset' do
      Lisonja.reset!
      "done <a href='/'>ok</a>"
    end

    get "/cron" do
      invoices_billed = []
      Lisonja::Customer.all.each do |customer|
        if billed_info = customer.bill!
          invoices_billed << billed_info
        end
      end
      "Just billed: #{invoices_billed.to_yaml}"
    end

    post "/savecreds" do
      Lisonja.save_creds(params[:auth_id], params[:auth_key])
      "ok"
    end

    post "/register" do
      Lisonja.register_regular_service(params[:service_registration_url])
      redirect "/"
    end

    post "/registerfancy" do
      Lisonja.register_fancy_service(params[:service_registration_url])
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

    template :generator do
<<-EOT
%h1= @generator.environment_name + " (" + @generator.id.to_s + ") "
- if @recent_message
  %strong Sent:
  = @recent_message
%form{:action=>"/customers/"+@customer.id.to_s+"/generators/"+@generator.id.to_s+"/generate_compliment", :method=>'POST'}
  %select{:name => 'message_type'}
    %option{:value => 'alert'} Alert
    %option{:value => 'notification'} Notification
    %option{:value => 'status'} Status
  %input{:value=>'Compliment the App Deployment', :type=>'submit'}
EOT
    end

    get "/customers/:customer_id/generators/:generator_id" do |customer_id, generator_id|
      @customer = Lisonja::Customer.find(customer_id)
      @generator = @customer.compliment_generators.find(generator_id)
      @recent_message = params[:message]
      haml :generator
    end

    post "/customers/:customer_id/generators/:generator_id/generate_compliment" do |customer_id, generator_id|
      @customer = Lisonja::Customer.find(customer_id)
      @generator = @customer.compliment_generators.find(generator_id)
      generated = @generator.generate_and_send_compliment(params[:message_type])
      redirect "/customers/#{customer_id}/generators/#{generator_id}?message=#{URI.escape(generated)}"
    end

    get "/customers/:customer_id" do |customer_id|
      @customer = Lisonja::Customer.find(customer_id)
      @recent_message = params[:message]
      if @customer
        haml :customer
      else
        halt 404, 'nonesuch customer'
      end
    end

    post "/customers/:customer_id/generate_compliment" do |customer_id|
      @customer = Lisonja::Customer.find(customer_id)
      generated = Lisonja.compliment_source.run!
      message = EY::ServicesAPI::Message.new(:message_type => params[:message_type], :subject => generated)
      Lisonja.connection.send_message(@customer.messages_url, message)
      redirect "/customers/#{@customer.id}?message=#{URI.escape(generated)}"
    end

    post "/api/1/customers/:customer_id/compliment_generators" do |customer_id|
      #parse the request
      provisioned_service = EY::ServicesAPI::ProvisionedServiceCreation.from_request(request.body.read)

      #do local persistence
      customer = Lisonja::Customer.find(customer_id)
      generator = customer.generate_generator(provisioned_service.environment.name, provisioned_service.messages_url)

      #sinatra stuff
      content_type :json
      headers 'Location' => generator.url

      #response with json about self
      response_hash = provisioned_service.creation_response_hash do |presenter|
        if generator.service_kind == "fancy"
          presenter.configuration_url = generator.configuration_url
          presenter.configuration_required = true
        else
          presenter.configuration_required = false
        end
        presenter.vars = {
          "COMPLIMENTS_API_KEY" => generator.api_key,
          "CIA_BACKDOOR_PASSWORD" => "toast"
        }
        presenter.url = generator.url
        presenter.message = EY::ServicesAPI::Message.new(:message_type => "status", :subject => generator.created_message)
      end

      response_hash.to_json
    end

    delete "/api/1/customers/:customer_id/compliment_generators/:generator_id" do |customer_id, generator_id|
      customer = Lisonja::Customer.find(customer_id)
      generator = customer.compliment_generators.find(generator_id)
      generator.decomission!
      content_type :json
      {}.to_json
    end

    get "/sso/customers/:customer_id" do |customer_id|
      raise "Signature invalid" unless EY::ApiHMAC.verify_for_sso(request.url, Lisonja.api_creds.auth_id, Lisonja.api_creds.auth_key)
      @customer = Lisonja::Customer.find(customer_id)
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

    post "/sso/customers/:customer_id/choose_plan" do |customer_id|
      @customer = Lisonja::Customer.find(customer_id)
      @customer.plan_type = params[:plan_type]
      @customer.save!

      message = EY::ServicesAPI::Message.new(:message_type => 'status', :subject => "#{params[:plan_type]} Activated!")
      Lisonja.connection.send_message(@customer.messages_url, message)

      redirect params[:ey_return_to_url]
    end
  
    get "/sso/customers/:customer_id/generators/:generator_id" do |customer_id, generator_id|
      #TODO: use a signature verification middleware instead?
      raise "Signature invalid" unless EY::ApiHMAC.verify_for_sso(request.url, Lisonja.api_creds.auth_id, Lisonja.api_creds.auth_key)
      @customer = Lisonja::Customer.find(customer_id)
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

    post "/sso/customers/:customer_id/generators/:generator_id/choose_type" do |customer_id, generator_id|
      @customer = Lisonja::Customer.find(customer_id)
      @generator = @customer.compliment_generators.find(generator_id)
      @generator.generator_type = params[:generator_type]
      @generator.save!

      message = EY::ServicesAPI::Message.new(:message_type => 'status', :subject => "#{params[:generator_type]} now available for #{@generator.environment_name}")
      Lisonja.connection.send_message(@generator.messages_url, message)

      redirect params[:ey_return_to_url]
    end

    post '/api/1/customers/:service_kind' do |service_kind|
      #parse the request
      service_account = EY::ServicesAPI::ServiceAccountCreation.from_request(request.body.read)

      service = Service.find_by_kind(service_kind)
      customer = service.customers.create!(
        :name => service_account.name,
        :api_url => service_account.url,
        :messages_url => service_account.messages_url,
        :invoices_url => service_account.invoices_url)

      #sinatra stuff
      content_type :json
      headers 'Location' => customer.url

      #response with json about self
      response_hash = service_account.creation_response_hash do |presenter|
        if service_kind == "fancy"
          presenter.configuration_required = true
          presenter.configuration_url = customer.configuration_url
        else
          presenter.configuration_required = false
        end
        presenter.provisioned_services_url = customer.provisioned_services_url
        presenter.url = customer.url
        presenter.message = EY::ServicesAPI::Message.new(:message_type => "status", :subject => customer.singup_message)
      end

      response_hash.to_json
    end

    delete "/api/1/customers/:customer_id" do |customer_id|
      @customer = Lisonja::Customer.find(customer_id)
      @customer.cancel!
      @customer.destroy
      content_type :json
      {}.to_json
    end
  end

  def self.connection
    @connection ||= EY::ServicesAPI::Connection.new(Lisonja.api_creds.auth_id, Lisonja.api_creds.auth_key, "Lisonja")
  end

  def self.setup!
    @connection = nil
    conn = Model.connection
    unless conn.table_exists?(:creds)
      conn.create_table "creds", :force => true do |t|
        t.string   "auth_id"
        t.string   "auth_key"
        t.datetime "created_at"
        t.datetime "updated_at"
      end
      conn.create_table "services", :force => true do |t|
        t.string   "name"
        t.string   "kind"
        t.string   "state"
        t.string   "url"
        t.datetime "created_at"
        t.datetime "updated_at"
      end
      conn.create_table "customers", :force => true do |t|
        t.references :service
        t.string   "name"
        t.string   "api_url"
        t.string   "messages_url"
        t.string   "invoices_url"
        t.string   "plan_type"
        t.datetime "last_billed_at"
        t.datetime "created_at"
        t.datetime "updated_at"
      end
      conn.create_table "compliment_generators", :force => true do |t|
        t.references :customer
        t.string   "environment_name"
        t.string   "api_key"
        t.string   "messages_url"
        t.string   "generator_type"
        t.datetime "decomissioned_at"
        t.datetime "last_billed_at"
        t.datetime "created_at"
        t.datetime "updated_at"
      end
    end
  end
  def self.teardown!
    conn = Model.connection
    conn.tables.each do |table_name|
      conn.drop_table(table_name)
    end
  end
  def self.reset!
    teardown!
    setup!
  end

  def self.api_creds
    Lisonja::Creds.first
  end
  def self.fancy_service
    Lisonja::Service.where(:kind => "fancy").first
  end
  def self.regular_service
    Lisonja::Service.where(:kind => "regular").first
  end
  def self.save_creds(auth_id, auth_key)
    raise "We already have creds!" if api_creds
    Lisonja::Creds.create!(:auth_id => auth_id, :auth_key => auth_key)
  end

  def self.register_regular_service(service_registration_url)
    create_service("Lisonja", "regular", regular_service_registration_params, service_registration_url)
  end

  def self.register_fancy_service(service_registration_url)
    create_service("Lisonja-Configured", "fancy", fancy_service_registration_params, service_registration_url)
  end

  def self.regular_service_registration_params
    {
      :name => "Lisonja", 
      :description => "my compliments to the devops", 
      :service_accounts_url =>     "#{ENV["URL_FOR_LISONJA"]}/api/1/customers/regular",
      :home_url =>                 "#{ENV["URL_FOR_LISONJA"]}/",
      :terms_and_conditions_url => "#{ENV["URL_FOR_LISONJA"]}/terms",
      :vars => [
        "COMPLIMENTS_API_KEY",
        "CIA_BACKDOOR_PASSWORD"
      ]
    }
  end

  def self.fancy_service_registration_params
    {
      :name => "Lisonja-Configured", 
      :description => "my compliments to the devops", 
      :service_accounts_url =>     "#{ENV["URL_FOR_LISONJA"]}/api/1/customers/fancy",
      :home_url =>                 "#{ENV["URL_FOR_LISONJA"]}/",
      :terms_and_conditions_url => "#{ENV["URL_FOR_LISONJA"]}/terms",
      :vars => [
        "COMPLIMENTS_API_KEY",
        "CIA_BACKDOOR_PASSWORD"
      ]
    }
  end

  def self.create_service(service_name, service_kind, registration_params, service_registration_url)
    service = Lisonja::Service.create!(:name => service_name, :kind => service_kind, :state => 'unregistered')
    remote_service = Lisonja.connection.register_service(service_registration_url, registration_params)
    service.url = remote_service.url
    service.state = "registered"
    service.save!
  end

end

require 'lisonja/generator'
Lisonja.compliment_source = Lisonja::PartiallyStolenComplimentGenerator
