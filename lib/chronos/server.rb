require 'sinatra/base'
require 'json'
require 'yaml'
require 'haml'
require 'chronos/server/models'

module Chronos
  module Server

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

      ##################
      # Actual Service #
      ##################

      post "/chronosapi/1/jobs" do
        api_protected!
        jobs.create!(JSON.parse(request.body.read))
        status 201
      end

      get "/chronosapi/1/jobs" do
        api_protected!
        jobs.map{|j| {:callback_url => j.callback_url, :schedule => j.schedule} }.to_json
      end

      #TODO: delete to an endpoint to remove some job you have

      ###################
      # Sinatra Helpers #
      ###################
      helpers do

        def jobs
          @scheduler.jobs
        end

        def api_protected!
          unless api_authorized?
            response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
            throw(:halt, [401, "Not authorized\n"])
          end
        end

        def api_authorized?
          @auth ||=  Rack::Auth::Basic::Request.new(request.env)
          if @auth.provided? && @auth.basic? && @auth.credentials
            username, password = @auth.credentials
            if @scheduler = Scheduler.find_by_auth_username(username)
              @scheduler.auth_password == password
            end
          end
        end

      end
    end

    ##################################
    # DB and EY API Connection setup #
    ##################################

    def self.ensure_tmp_dir
      require 'fileutils'
      FileUtils.mkdir_p(File.expand_path("../../../tmp/", __FILE__))
      FileUtils.mkdir_p(File.expand_path("../../../config/", __FILE__))
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

  end
end