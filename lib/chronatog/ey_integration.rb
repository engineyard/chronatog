require 'chronatog/server'
require 'ey_api_hmac'
require 'ey_services_api'
require 'chronatog/ey_integration/models'
require 'chronatog/ey_integration/controllers/api'
require 'chronatog/ey_integration/controllers/sso'

module Chronatog
  module EyIntegration
    API_PATH_PREFIX = "/eyintegration/api/1"
    SSO_PATH_PREFIX = "/eyintegration/sso"

    def self.app
      Rack::Builder.new do
        map "/" do
          run Chronatog::Server::Application
        end
        map API_PATH_PREFIX do
          run Chronatog::EyIntegration::Controller::API
        end
        map SSO_PATH_PREFIX do
          run Chronatog::EyIntegration::Controller::SSO
        end
      end
    end

    ####################################
    # Registering this service with EY #
    ####################################

    def self.register_service(service_registration_url, base_url)
      create_service(service_registration_params(base_url), service_registration_url)
    end

    def self.service_registration_params(base_url)
      {
        :name => "Chronatog",
        :label => "chronatog",
        :description => "Web cron as a service.",
        :service_accounts_url =>     "#{base_url + API_PATH_PREFIX}/customers",
        :home_url =>                 "#{base_url}/",
        :terms_and_conditions_url => "#{base_url}/terms",
        :vars => ["service_url", "auth_username", "auth_password"]
      }
    end

    def self.create_service(registration_params, service_registration_url)
      remote_service = connection.register_service(service_registration_url, registration_params)
      service.update_attributes!(:url => remote_service.url)
    end

    #############################
    # DB setup/teardown helpers #
    #############################

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

    ################################
    # Connection for talking to EY #
    ################################

    def self.connection
      unless EY::ServicesAPI.setup?
        EY::ServicesAPI.setup!(:auth_id => api_creds.auth_id, :auth_key => api_creds.auth_key)
      end
      EY::ServicesAPI.connection
    end

    #################################
    # Credentials for talking to EY #
    #################################

    def self.api_creds
      @creds ||= EyCredentials.first || EyCredentials.create!
    end

    def self.save_creds(auth_id, auth_key)
      api_creds.update_attributes!(:auth_id => auth_id, :auth_key => auth_key)
      api_creds
    end

    #################################
    # Service as registered with EY #
    #################################

    def self.service
      @service ||= EyService.first || EyService.create!
    end

  end
end