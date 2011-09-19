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
        #TODO: hmac the other way!
        #1. lookup the scheduler by auth_id
        #2. add a job to the scheduler based on the params given
        {}.to_json
      end

      get "/chronosapi/1/jobs" do
        #TODO: hmac the other way!
        #1. lookup the scheduler by auth_id
        #2. list jobs for that scheduler
        [].to_json
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