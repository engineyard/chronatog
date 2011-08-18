module EY
  module ServicesAPI
    class ProvisionedServiceCreation < APIStruct.new(:url, :environment, :app, :messages_url)

      def initialize(*args)
        super(*args)
        self.environment = Environment.new(self.environment)
        self.app = App.new(self.app)
      end

      def self.from_request(request)
        json = JSON.parse(request)
        new(json)
      end

      class App < APIStruct.new(:id, :name)
      end

      class Environment < APIStruct.new(:id, :name, :framework_env)
      end

      # def environment
      #   debugger
      #   Environment.new(@environment)
      # end

      def creation_response_hash
        response_presenter = ProvisionedServiceResponse.new
        yield response_presenter
        response_presenter.to_hash
      end

    end
  end
end