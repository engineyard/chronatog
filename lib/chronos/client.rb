require 'ey_api_hmac'

module Chronos
  module Client

    def self.connection
      @connection ||= Connection.new(env_var("CHRONOS_AUTH_ID"), env_var("CHRONOS_AUTH_KEY"))
    end

    class Connection < EY::ApiHMAC::BaseConnection
      #TODO auth!

      def create_job(callback_url, job_schedule)
        post(Chronos::Client.chronos_service_url, {:callback_url => callback_url, :job_schedule => job_schedule})
      end

      def destroy_job(job_url)
        delete(job_url)
      end

      def list_jobs
        get(Chronos::Client.chronos_service_url) do |json_body, response_location|
          json_body
        end
      end

    end

    protected

    def self.chronos_service_url
      env_var("CHRONOS_SERVICE_URL")
    end

    private

    def self.env_var(var)
      ENV[var] || (raise "missing environment variable: #{var}")
    end

  end

end
