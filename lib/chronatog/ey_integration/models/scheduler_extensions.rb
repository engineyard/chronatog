module Chronatog
  module EyIntegration
    module SchedulerExtensions

      def decomission!
        self.decomissioned_at = Time.now
        save!
      end

#{reset_auth_definition{
      def reset_auth!
        self.auth_username = "U"+SecureRandom.hex(7)
        self.auth_password = "P"+SecureRandom.hex(13)
        EY::ServicesAPI.connection.update_provisioned_service(self.api_url, {
          "vars" => { "auth_username" => self.auth_username,
                      "auth_password" => self.auth_password }})
        save!
      end
#}reset_auth_definition}

      #TODO: make sure you can't add/remove jobs to decomissioned schedulers

    end
  end
end