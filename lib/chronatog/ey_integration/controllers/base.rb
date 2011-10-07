module Chronatog
  module EyIntegration
    module Controller
      class Base < Sinatra::Base
        enable :raise_errors
        disable :dump_errors
        disable :show_exceptions

        ######################
        # Sintra app helpers #
        ######################

        def api_base_url
          true_base_url + API_PATH_PREFIX
        end

        def sso_base_url
          true_base_url + SSO_PATH_PREFIX
        end

        def true_base_url
          uri = URI.parse(request.url)
          uri.to_s.gsub(uri.request_uri, '')
        end

        def service
          Chronatog::Server::Service.first || (raise "service not setup")
        end

      end
    end
  end
end
