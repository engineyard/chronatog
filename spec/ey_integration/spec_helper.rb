require 'chronos/ey_integration'

shared_context "ey integration reset" do
  before(:each) do
    Chronos::EyIntegration.reset!
    EY::ServicesAPI.enable_mock!
    @mock_backend = EY::ServicesAPI.mock_backend
    @mock_backend.connection_to_partner.backend = Chronos::EyIntegration.app
  end
end