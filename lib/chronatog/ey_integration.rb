require 'chronatog/server'
require 'ey_api_hmac'
require 'ey_services_api'
require 'chronatog/ey_integration/models'
require 'chronatog/ey_integration/application'

module Chronatog
  module EyIntegration
    PATHPREFIX = "/eyintegration"

    def self.app
      Rack::Builder.new do
        map "/" do
          run Chronatog::Server::Application
        end
        map PATHPREFIX do
          run Chronatog::EyIntegration::Application
        end
      end
    end

    ####################################
    # Registering this service with EY #
    ####################################

    #TODO: make a rake task for registering

    def self.register_service(service_registration_url, base_url)
      #TODO: raise if we don't have any credentials
      create_service("Chronatog", service_registration_params(base_url), service_registration_url)
    end

    def self.service_registration_params(base_url)
      {
        :name => "Chronatog",
        :description => "Web cron as a service.",
        :service_accounts_url =>     "#{base_url + PATHPREFIX}/api/1/customers",
        :home_url =>                 "#{base_url}/",
        :terms_and_conditions_url => "#{base_url}/terms",
        :vars => ["CHRONOS_AUTH_USERNAME", "CHRONOS_AUTH_PASSWORD", "CHRONOS_SERVICE_URL"]
      }
    end

    def self.create_service(service_name, registration_params, service_registration_url)
      service = Chronatog::Server::Service.create!(:name => service_name, :state => 'unregistered')
      remote_service = connection.register_service(service_registration_url, registration_params)
      service.url = remote_service.url
      service.state = "registered"
      service.save!
      service
    end

    #################################
    # Credentials for talking to EY #
    #################################

    def self.setup!
      if api_creds
        EY::ServicesAPI.setup!(:auth_id => api_creds.auth_id, :auth_key => api_creds.auth_key)
      end
    end

    def self.connection
      EY::ServicesAPI.connection
    end

    def self.api_creds
      @creds ||= Credentials.load
    end

    def self.save_creds(auth_id, auth_key)
      Credentials.write!(auth_id, auth_key)
    end

    def self.destroy_creds
      api_creds.destroy if api_creds
    end

    class Credentials < Struct.new(:auth_id, :auth_key)
      CONFIG_PATH = File.expand_path('../../../config/ey_partner_credentials.yml', __FILE__)
      def self.load
        if File.exists?(CONFIG_PATH)
          creds = YAML.load_file(CONFIG_PATH)
          Credentials.new(creds[:auth_id], creds[:auth_key])
        end
      end
      def self.write!(auth_id, auth_key)
        creds = Credentials.new(auth_id, auth_key)
        File.open(CONFIG_PATH, "w") do |fp|
          fp.write({:auth_id => creds.auth_id, :auth_key => creds.auth_key}.to_yaml)
        end
        creds
      end
      def destroy
        FileUtils.rm_f(CONFIG_PATH)
      end
    end

    def self.setup!
      Chronatog::Server.setup!
      Schema.setup!
    end

    def self.teardown!
      Chronatog::Server.teardown!
    end

    def self.reset!
      teardown!
      setup!
    end

  end
end