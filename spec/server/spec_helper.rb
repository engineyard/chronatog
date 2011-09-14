require 'chronos'
require 'chronos/server'

RSpec.configure do |config|
  config.before(:each) do
    Chronos::Server.reset!
    EY::ServicesAPI.enable_mock!
    EY::ServicesAPI.mock_backend.connection_to_partner.backend = Chronos::Server::Application
  end
end