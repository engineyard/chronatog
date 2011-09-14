require 'chronos'

Chronos.setup!
RSpec.configure do |config|
  config.before(:each) do
    Chronos.reset!
    EY::ServicesAPI.enable_mock!
    EY::ServicesAPI.mock_backend.connection_to_partner.backend = Chronos::Application
  end
end