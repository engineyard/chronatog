require 'rack/client'

module Chronatog
  module Client

    def self.setup!(service_url, auth_username, auth_password)
      if service_url == "in-memory"
        @connection = Fake.new
      else
        @connection = Connection.new(service_url, auth_username, auth_password)
      end
    end

    def self.connection
      @connection or raise "connection not setup! yet"
    end

    class Fake
      def create_job(callback_url, schedule)
        job_url = "/jobs/#{Object.new.object_id}"
        created = {'callback_url' => callback_url, 'schedule' => schedule, 'url' => job_url }
        jobs[job_url] = created
        JSON::parse(created.to_json)
      end

      def destroy_job(job_url)
        jobs.delete(job_url)
      end

      def list_jobs
        JSON::parse(jobs.values.to_json)
      end

      def get_job(job_url)
        JSON::parse(jobs[job_url].to_json)
      end

    private

      def jobs
        self.class.jobs
      end
      def self.jobs
        @jobs ||= {}
      end

    end

    class Connection
      def initialize(service_url, auth_username, auth_password)
        @service_url = service_url
        @creds = [auth_username, auth_password]
        @standard_headers = {
          'CONTENT_TYPE' => 'application/json',
          'Accept' => 'application/json'
        }
      end

      def create_job(callback_url, schedule)
        response = client.post(@service_url, @standard_headers, {:callback_url => callback_url, :schedule => schedule}.to_json)
        if response.status == 201
          JSON.parse(response.body)
        else
          raise "Unexpected response #{response.status}: #{response.body}"
        end
      end

      def destroy_job(job_url)
        response = client.delete(job_url)
        unless response.status == 200
          raise "Unexpected response #{response.status}: #{response.body}"
        end
      end

      def list_jobs
        response = client.get(@service_url, @standard_headers)
        if response.status == 200
          JSON.parse(response.body)
        else
          raise "Unexpected response #{response.status}: #{response.body}"
        end
      end

      def get_job(job_url)
        response = client.get(job_url, @standard_headers)
        if response.status == 200
          JSON.parse(response.body)
        else
          raise "Unexpected response #{response.status}: #{response.body}"
        end
      end

      attr_writer :backend
      def backend
        @backend ||= Rack::Client::Handler::NetHTTP
      end

      protected

      def client
        #need to set vars in scope here because Rack::Client.new instance_evals
        bak = backend
        creds = @creds
        @client ||= Rack::Client.new do
          use BasicAuth, creds
          run bak
        end
      end

      private

      class BasicAuth
        def initialize(app, creds)
          @app = app
          @username, @password = creds
        end

        def call(env)
          env["HTTP_AUTHORIZATION"] = 'Basic ' + ["#{@username}:#{@password}"].pack('m').delete("\r\n")
          @app.call(env)
        end
      end

    end

  end

end
