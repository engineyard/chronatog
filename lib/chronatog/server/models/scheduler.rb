module Chronatog
  module Server
    class Scheduler < Model
      belongs_to :customer
      has_many :jobs

      after_initialize do
        #The proper thing to do with ruby 1.9 is to call force_encoding("UTF-8") on the strings
        #But this method doesn't exist in 1.8.7
        #Prefixing with a non-hex character prevents the string from being hex encoded, 
        #which when stored in the DB fails to be fetched with a query using a non-hex string (as would come in a request)
        self.auth_username ||= "U"+SecureRandom.hex(7)
        self.auth_password ||= "P"+SecureRandom.hex(13)
      end

    end
  end
end