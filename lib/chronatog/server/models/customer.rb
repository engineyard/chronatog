module Chronatog::Server
  class Customer < Model
    has_many :schedulers, :dependent => :destroy
  end
end
