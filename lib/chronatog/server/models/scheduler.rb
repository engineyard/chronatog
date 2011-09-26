module Chronatog
  module Server
    class Scheduler < Model
      belongs_to :customer
      has_many :jobs

      after_initialize do
        self.auth_username ||= SecureRandom.hex(7)
        self.auth_password ||= SecureRandom.hex(13)
      end

    end
  end
end