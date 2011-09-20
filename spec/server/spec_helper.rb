require 'chronos/server'
require 'chronos/client'

RSpec.configure do |config|
  config.before(:each) do
    Chronos::Server.reset!
  end
end