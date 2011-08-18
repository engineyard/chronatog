module EY
  module ServicesAPI
    class Service < APIStruct.new(:name, :description, :home_url, :service_accounts_url, :terms_and_conditions_url, :vars)
      attr_accessor :connection
      attr_accessor :url

      def update(atts)
        new_atts = self.to_hash.merge(atts)
        connection.update_service(self.url, new_atts)
        update_from_hash(new_atts)
      end

      def destroy
        connection.destroy_service(self.url)
      end

    end
  end
end