module Chronatog::Server
  class Customer < Model
    has_many :schedulers
  end
end
