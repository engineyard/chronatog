module EY
  module ServicesAPI
    class ServiceAccountResponse < Struct.new(:configuration_required, :configuration_url, :message, :provisioned_services_url, :url)
      def to_hash
        {
          :service_account => {
            :url => self.url,
            :configuration_required => self.configuration_required,
            :configuration_url => self.configuration_url,
            :provisioned_services_url => self.provisioned_services_url
          },
          :message => self.message.to_hash
        }
      end
    end
  end
end