require 'chronos/server'

RSpec.configure do |config|
  config.before(:each) do
    Chronos::Server.reset!
  end
end