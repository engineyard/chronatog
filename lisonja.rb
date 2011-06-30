require 'sinatra'
require 'rest-client'
require 'json'
require 'yaml'
require 'haml'

class Lisonja < Sinatra::Base
  enable :raise_errors
  disable :dump_errors
  disable :show_exceptions

  class << self
    attr_accessor :compliment_source
  end

  get "/" do
    to_output = ""
    if @@service_url
      to_output += "I am Lisonja, I think you're swell. (registered as #{@@service_url}) "
    else
      to_output += <<-EOT
  Register this service:
    <form action="/register" method="POST">
      <label for="service_registration_url">Service Registration API URL</label>
      <input id="service_registration_url" name="service_registration_url" type="text" />
      <input value="Register" type="submit" />
    </form>
EOT
    end
    to_output += "current customer info: <pre>#{@@customers_hash.to_yaml}</pre>"
    to_output
  end

  post "/register" do
    Lisonja.create_service(params[:service_registration_url])
    redirect "/"
  end

  get "/terms" do
    "Agree to our terms, or else..."
  end

  template :generators do
<<-EOT
%h1= @customer.name + " (" + @customer.id.to_s + ") "
- if @recent_message
  %strong Sent:
  = @recent_message
%ul
  - @customer.compliment_generators.each do |g|
    %li
      - message_url = "/customers/" + @customer.id.to_s + "/compliment_generators/" + g.id.to_s + "/generate"
      %form{:action=>message_url, :method=>'POST'}
        %input{:value=>'Send compliment.', :type=>'submit'}
EOT
  end
  
  template :customers do
<<-EOT
%h1= Customers
%ul
  - @@customers_hash.values.each do |customer|
    %li
      %a{:href=>customer.url}
        = customer.name + " (" + customer.id + ")"
EOT
    
  end
  
  get "customers" do
    haml customers
  end

  get "/customers/:customer_id" do |customer_id|
    @customer = @@customers_hash[customer_id.to_s]
    @recent_message = params[:message]
    if @customer
      haml :generators
    else
      halt 404, 'nonesuch customer'
    end
  end
  
  post "/customers/:customer_id/compliment_generators/:generator_id/generate" do |customer_id, generator_id|
    customer = @@customers_hash[customer_id.to_s]
    generator = customer.compliment_generators.detect{|g| g.id.to_s == generator_id.to_s}
    generated = generator.generate_compliment!
    redirect "/customers/#{customer.id}?message=#{generated}"
  end

  post "/api/1/customers/:customer_id/compliment_generators" do |customer_id|
    params = JSON.parse(request.body.read)
    customer = @@customers_hash[customer_id.to_s]
    #TODO: find a way to make the generator different depending on app or env (for benefit of example)
    generator = customer.generate_generator(params[:messages_url])
    headers 'Location' => generator.url
    {
      :provisioned_service => generator.as_json,
      :message => Message.new('status', generator.created_message).as_json
    }.to_json
  end

  class ComplimentGenerator < Struct.new(:id, :api_key, :messages_url, :url)
    def as_json
      {
        :url => url,
        :configuration_url => nil, #meaning, no configuration possible
        :vars => {
          "COMPLIMENTS_API_KEY" => api_key,
          "CIA_BACKDOOR_PASSWORD" => "toast"
        }
      }
    end
    def created_message
      "Compliment Generator Generated!"
    end
    def generate_compliment!
      Lisonja.compliment_source.run!
    end
    def self.generate(customer_id, messages_url)
      @@generators_count ||= 0
      next_id = @@generators_count += 1
      ComplimentGenerator.new(
        next_id, 
        rand.to_s[2,10], 
        messages_url,
        "#{ENV["URL_FOR_LISONJA"]}/api/1/customers/#{customer_id}/compliment_generators/#{next_id}")
    end
  end

  class Customer < Struct.new(:id, :name, :api_url, :messages_url, :invoices_url, :url)
    def as_json
      {
        :url => url,
        :configuration_required => false,
        :configuration_url  => nil, #meaning, no configuration possible
        :provisioned_services_url  => "#{url}/compliment_generators"
      }
    end
    def singup_message
      "You enabled Lisonja. Well done #{name}!"
    end
    def compliment_generators
      @compliment_generators ||= []
    end
    def generate_generator(messages_url = nil)
      generator = ComplimentGenerator.generate(id, messages_url)
      self.compliment_generators << generator
      generator
    end
    def self.create(customers_hash, name, url = nil, messages_url = nil, invoices_url = nil)
      @@customer_count ||= 0
      next_id = @@customer_count += 1
      customer = Customer.new(
                    next_id, name, url, messages_url, invoices_url,
                    "#{ENV["URL_FOR_LISONJA"]}/api/1/customers/#{next_id}")
      customers_hash[customer.id.to_s] = customer
      customer
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
  end

  post '/api/1/customers' do
    params = JSON.parse(request.body.read)
    customer = Customer.create(
                  @@customers_hash,
                  params['name'], 
                  params['url'], 
                  params['messages_url'], 
                  params['invoices_url'])
    headers 'Location' => customer.url
    {
      :service_account => customer.as_json,
      :message => Message.new('status', customer.singup_message).as_json
    }.to_json
  end

  def self.reset!
    @@service_url = nil
    @@customers_hash = {}
  end
  def self.seed_data
    Customer.create(@@customers_hash, "barbara").generate_generator
    Customer.create(@@customers_hash, "josephine").generate_generator
    Customer.create(@@customers_hash, "Pedro").generate_generator
  end

  def self.create_service(service_registration_url)
    unless @@service_url
      service_creation_params = {
        :service =>
        {
          :name =>                     "Lisonja",
          :description =>              "my compliments to the devops",
          :service_accounts_url =>     "#{ENV["URL_FOR_LISONJA"]}/api/1/customers",
          :home_url =>                 "#{ENV["URL_FOR_LISONJA"]}/",
          :terms_and_conditions_url => "#{ENV["URL_FOR_LISONJA"]}/terms",
          :vars => [
              "COMPLIMENTS_API_KEY",
              "CIA_BACKDOOR_PASSWORD"
          ]
        }
      }
      response = RestClient.post(
                          service_registration_url,
                          service_creation_params.to_json,
                          :content_type => :json,
                          :accept => :json, :user_agent => "Lisonja")
      response_data = JSON.parse(response.body)
      @@service_url = response.headers[:location]
    end
    @@service_url
  end

  def self.customers
    @@customers_hash.values
  end

end

require File.expand_path("../generator", __FILE__)
Lisonja.compliment_source = PartiallyStolenComplimentGenerator
