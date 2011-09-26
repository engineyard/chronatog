require 'rack/client'

module Chronatog
  module Client

    def self.setup!(service_url, auth_username, auth_password)
      @connection = Connection.new(service_url, auth_username, auth_password)
    end

    def self.connection
      @connection or raise "connection not setup! yet"
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
        bak = @backend
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
