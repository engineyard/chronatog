module EY
  module ServicesAPI
    class ProvisionedServiceResponse < Struct.new(:configuration_required, :configuration_url, :message, :vars, :url)
      def to_hash
        {
          :provisioned_service      => {
            :url                    => self.url,
            :configuration_required => self.configuration_required,
            :configuration_url      => self.configuration_url,
            :vars                   => self.vars,
          },
          :message                  => self.message.to_hash,
        }
      end
    end
  end
end