require 'sinatra'
require 'rest-client'
require 'json'
require 'yaml'
require 'haml'
require 'ey_api_hmac'

class Lisonja < Sinatra::Base
  enable :raise_errors
  disable :dump_errors
  disable :show_exceptions

  class << self
    attr_accessor :compliment_source
  end

  get "/" do
    to_output = ""
    if !@@services["regular"]
      to_output += <<-EOT
        <div id="basic">
        Register the Regular Lisonja service:<br/>
          <form action="/register" method="POST">
            <label for="service_registration_url">Service Registration API URL</label>
            <input id="service_registration_url" name="service_registration_url" type="text" />
            
            <label for="api_secret">API Secret</label>
            <input id="api_secret" name="api_secret" type="text" />
            
            <input value="Register" type="submit" />
          </form>
        </div>
      EOT
    else
      to_output += "Regular lisona registered as #{@@services["regular"][:service_url]} <br/>"
    end
    if !@@services["fancy"]
      to_output += <<-EOT
        <div id="configured">
        Register the Highly Configured Fancy Lisonja service:<br/>
          <form action="/registerfancy" method="POST">
            <label for="service_registration_url">Service Registration API URL</label>
            <input id="service_registration_url" name="service_registration_url" type="text" />
            
            <label for="api_secret">API Secret</label>
            <input id="api_secret" name="api_secret" type="text" />
            
            <input value="Register" type="submit" />
          </form>
        </div>
      EOT
    else
      to_output += "Fancy lisona registered as #{@@services["fancy"][:service_url]} <br/>"
    end
    to_output += "<a href='/cron'>run billing cron</a> <br/>"
    to_output += "current customer info: <pre>#{@@customers_hash.to_yaml}</pre>"
    @@customers_hash.values.each do |customer|
      to_output += "<a href='/customers/#{customer.id}'>#{customer.name}</a>"
    end
    to_output
  end

  get "/cron" do
    invoices_billed = []
    @@customers_hash.values.each do |customer|
      if billed_info = customer.bill!
        invoices_billed << billed_info
      end
    end
    "Just billed: #{invoices_billed.to_yaml}"
  end

  post "/register" do
    Lisonja.register_regular_service(params[:service_registration_url], params[:api_secret])
    redirect "/"
  end

  post "/registerfancy" do
    Lisonja.register_fancy_service(params[:service_registration_url], params[:api_secret])
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
    = compliment_generator.name
EOT
  end

  template :generator do
<<-EOT
%h1= @generator.name + " (" + @generator.id.to_s + ") "
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
    @customer = @@customers_hash[customer_id.to_s]
    @generator = @customer.compliment_generators.detect{|g| g.id.to_s == generator_id.to_s}
    @recent_message = params[:message]
    haml :generator
  end

  post "/customers/:customer_id/generators/:generator_id/generate_compliment" do |customer_id, generator_id|
    @customer = @@customers_hash[customer_id.to_s]
    @generator = @customer.compliment_generators.detect{|g| g.id.to_s == generator_id.to_s}
    generated = @generator.generate_and_send_compliment(params[:message_type])
    redirect "/customers/#{customer_id}/generators/#{generator_id}?message=#{URI.escape(generated)}"
  end

  get "/customers/:customer_id" do |customer_id|
    @customer = @@customers_hash[customer_id.to_s]
    @recent_message = params[:message]
    if @customer
      haml :customer
    else
      halt 404, 'nonesuch customer'
    end
  end

  post "/customers/:customer_id/generate_compliment" do |customer_id|
    customer = @@customers_hash[customer_id.to_s]
    #TODO: 1 main generator for complimenting all customers, instead of gen new one each time?
    generator = ComplimentGenerator.generate(customer_id, "regular", nil, "TODO messages url...?")
    generated = generator.generate_compliment!
    customer.send_compliment(params[:message_type], generated)
    redirect "/customers/#{customer.id}?message=#{URI.escape(generated)}"
  end

  # post "/customers/:customer_id/compliment_generators/:generator_id/generate" do |customer_id, generator_id|
  #   customer = @@customers_hash[customer_id.to_s]
  #   generator = customer.compliment_generators.detect{|g| g.id.to_s == generator_id.to_s}
  #   generated = generator.generate_compliment!
  #   customer.send_compliment(params[:message_type], generated)
  #   redirect "/customers/#{customer.id}?message=#{URI.escape(generated)}"
  # end

  post "/api/1/customers/:customer_id/compliment_generators" do |customer_id|
    params = JSON.parse(request.body.read)
    customer = @@customers_hash[customer_id.to_s]
    #TODO: find a way to make the generator different depending on app or env (for benefit of example)
    generator = customer.generate_generator(params["environment"]["name"], params['messages_url'])
    content_type :json
    headers 'Location' => generator.url
    {
      :provisioned_service => generator.as_json,
      :message => Message.new('status', generator.created_message).as_json
    }.to_json
  end

  get "/sso/customers/:customer_id" do |customer_id|
    #TODO: a better way to know we are using the 'fancy' service
    raise "Signature invalid" unless EY::ApiHMAC.verify_for_sso(request.url, Lisonja.services["fancy"][:api_secret])
    @customer = @@customers_hash[customer_id.to_s]
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
    @customer = @@customers_hash[customer_id.to_s]
    @customer.plan_type = params[:plan_type]
    Message.send_message(@customer.messages_url, :status, "#{params[:plan_type]} Activated!")
    redirect params[:ey_return_to_url]
  end
  
  get "/sso/customers/:customer_id/generators/:generator_id" do |customer_id, generator_id|
    #TODO: a better way to know we are using the 'fancy' service
    #TODO: turn on verifying again when signature is using correct secret..
    # raise "Signature invalid" unless EY::ApiHMAC.verify_for_sso(request.url, Lisonja.services["fancy"][:api_secret])
    @customer = @@customers_hash[customer_id.to_s]
    @generator = @customer.compliment_generators.detect{ |g| g.id.to_s == generator_id.to_s }
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
    @customer = @@customers_hash[customer_id.to_s]
    @generator = @customer.compliment_generators.detect{ |g| g.id.to_s == generator_id.to_s }
    @generator.generator_type = params[:generator_type]
    Message.send_message(@generator.messages_url, :status, "#{params[:generator_type]} now available for #{@generator.name}")
    redirect params[:ey_return_to_url]
  end


  class ComplimentGenerator < Struct.new(:id, :service_kind, :name, :api_key, :messages_url, :customer_id, :generator_type)
    def initialize(*args)
      super(*args)
      @created_at = Time.now
    end
    def url
      "#{ENV["URL_FOR_LISONJA"]}/api/1/customers/#{customer_id}/compliment_generators/#{id}"
    end
    def configuration_url
      "#{ENV["URL_FOR_LISONJA"]}/sso/customers/#{customer_id}/generators/#{id}"
    end
    def as_json
      if service_kind == "fancy"
        {
          :url => url,
          :configuration_url => configuration_url,
          :configuration_required => true,
          :vars => {
            "COMPLIMENTS_API_KEY" => api_key,
            "CIA_BACKDOOR_PASSWORD" => "toast"
          }
        }
      else
        {
          :url => url,
          :configuration_url => nil, #meaning, no configuration possible
          :vars => {
            "COMPLIMENTS_API_KEY" => api_key,
            "CIA_BACKDOOR_PASSWORD" => "toast"
          }
        }
      end
    end
    def created_message
      "Compliment Generator Generated!"
    end
    def generate_compliment!
      Lisonja.compliment_source.run!
    end
    def self.generate(customer_id, service_kind, name, messages_url)
      @@generators_count ||= 0
      next_id = @@generators_count += 1
      ComplimentGenerator.new(
        next_id, 
        service_kind,
        name,
        rand.to_s[2,10], 
        messages_url,
        customer_id,
        "default")
    end
    def generate_and_send_compliment(message_type)
      compliment = generate_compliment!
      message = Message.new(message_type, compliment, nil)
      message.send_message(self.messages_url)
      compliment
    end
    def get_billable_usage!(at_time)
      last_billed_at = @last_billed_at || @created_at
      to_return = (at_time.to_i - last_billed_at.to_i)
      @last_billed_at = at_time
      to_return
    end
  end

  class Customer < Struct.new(:id, :service_kind, :name, :api_url, :messages_url, :invoices_url, :plan_type)
    def initialize(*args)
      super(*args)
      @created_at = Time.now
    end
    def url
      "#{ENV["URL_FOR_LISONJA"]}/api/1/customers/#{id}"
    end
    def as_json
      to_return = {
        :url => url,
        :configuration_required => false,
        :configuration_url  => nil, #meaning, no configuration possible
        :provisioned_services_url  => "#{url}/compliment_generators"
      }
      if service_kind == "fancy"
        to_return.merge!(
          :configuration_required => true,
          :configuration_url => "#{ENV["URL_FOR_LISONJA"]}/sso/customers/#{id}"
        )
      end
      to_return
    end
    def singup_message
      "You enabled Lisonja. Well done #{name}!"
    end
    def compliment_generators
      @compliment_generators ||= []
    end
    def generate_generator(env_name = nil, messages_url = nil)
      generator = ComplimentGenerator.generate(id, service_kind, env_name, messages_url)
      self.compliment_generators << generator
      generator
    end
    def send_compliment(message_type, compliment)
      message = Message.new(message_type, compliment, nil)
      message.send_message(self.messages_url)
    end
    def self.create(customers_hash, service_kind, name, api_url = nil, messages_url = nil, invoices_url = nil)
      @@customer_count ||= 0
      next_id = @@customer_count += 1
      customer = Customer.new(
                    next_id, service_kind, name, api_url, messages_url, invoices_url, "default")
      customers_hash[customer.id.to_s] = customer
      customer
    end
    def bill!
      last_billed_at = @last_billed_at || @created_at
      billing_at = Time.now
      #this service costs $0.01 per minute
      total_price = 1 * (billing_at.to_i - last_billed_at.to_i) / 60
      compliment_generators.each do |g|
        usage_seconds = g.get_billable_usage!(billing_at)
        #compliment generators costs $0.02 per second
        usage_price = usage_seconds * 2
        total_price += usage_price
      end
      if total_price > 0
        #TODO: charge per compliment generator?
        invoice_params = {
          :invoice => {
            :total_amount_cents => total_price,
            :line_item_description => "For service from #{last_billed_at} to #{billing_at}, "+
                                      "includes #{compliment_generators.size} compliment generators."
          }
        }
        response = RestClient.post(
                            invoices_url,
                            invoice_params.to_json,
                            :content_type => :json,
                            :accept => :json, :user_agent => "Lisonja")
        response_data = JSON.parse(response.body)
        #TODO: do something with the response?
        @last_billed_at = billing_at
        #return info about charges made
        invoice_params
      else
        #return no charge made
        nil
      end
    end
    def cancel!
      bill!
      @compliment_generators = []
    end
  end

  class Message < Struct.new(:message_type, :subject, :body)
    def as_json
      {
        :message_type => message_type,
        :subject => subject,
        :body => body
      }
    end
    def send_message(messages_url)
      RestClient.post(messages_url, {:message => as_json}.to_json, :content_type => :json,
        :accept => :json, :user_agent => "Lisonja")
    end

    def self.send_message(to, message_type, subject, body=nil)
      Message.new(message_type, subject, body).send_message(to)
    end
  end

  post '/api/1/customers/:service_kind' do |service_kind|
    params = JSON.parse(request.body.read)
    customer = Customer.create(
                  @@customers_hash,
                  service_kind,
                  params['name'], 
                  params['url'], 
                  params['messages_url'], 
                  params['invoices_url'])
    content_type :json
    headers 'Location' => customer.url
    to_return = {
      :service_account => customer.as_json,
      :message => Message.new('status', customer.singup_message).as_json
    }
    to_return.to_json
  end

  delete "/api/1/customers/:customer_id" do |customer_id|
    @customer = @@customers_hash[customer_id.to_s]
    @customer.cancel!
    @@customers_hash.delete(customer_id.to_s)
    content_type :json
    {}.to_json
  end

  def self.reset!
    @@services = {}
    @@customers_hash = {}
  end
  def self.seed_data
    Customer.create(@@customers_hash, "barbara").generate_generator
    Customer.create(@@customers_hash, "josephine").generate_generator
    Customer.create(@@customers_hash, "Pedro").generate_generator
  end

  def self.register_regular_service(service_registration_url, api_secret)
    create_service("Lisonja", "regular", service_registration_url, api_secret)
  end

  def self.register_fancy_service(service_registration_url, api_secret)
    create_service("Lisonja-Configured", "fancy", service_registration_url, api_secret)
  end

  def self.create_service(service_name, service_kind, service_registration_url, api_secret)
    service_creation_params = {
      :service =>
      {
        :name =>                     service_name,
        :description =>              "my compliments to the devops",
        :service_accounts_url =>     "#{ENV["URL_FOR_LISONJA"]}/api/1/customers/#{service_kind}",
        :home_url =>                 "#{ENV["URL_FOR_LISONJA"]}/",
        :terms_and_conditions_url => "#{ENV["URL_FOR_LISONJA"]}/terms",
        :vars => [
            "COMPLIMENTS_API_KEY",
            "CIA_BACKDOOR_PASSWORD"
        ]
      }
    }
    # RackClient.register_middleware(HMACAutho, api_secret)
    # RackClient.post
    response = RestClient.post(
                        service_registration_url,
                        service_creation_params.to_json,
                        :content_type => :json,
                        :accept => :json, :user_agent => "Lisonja")
    response_data = JSON.parse(response.body)
    @@services[service_kind] = {}
    @@services[service_kind][:api_secret] = api_secret
    @@services[service_kind][:service_url] = response.headers[:location]
    Service.new(service_name, service_kind, @@services[service_kind][:service_url], @@services[service_kind][:api_secret])
  end

  class Service < Struct.new(:name, :service_kind, :service_url, :api_secret)
  end

  def self.customers
    @@customers_hash.values
  end
  def self.services
    @@services
  end

end

require File.expand_path("../generator", __FILE__)
Lisonja.compliment_source = PartiallyStolenComplimentGenerator
