require File.join( File.dirname(__FILE__), "spec_helper" )

describe "setup" do
  before do
    @mock_backend = EY::ServicesAPI.mock_backend
  end

  describe "with the service registered" do
    before do
      # Chronos::Eyintegration.save_creds(@mock_backend.partner[:auth_id], @mock_backend.partner[:auth_key])
      base_url = "http://chronos.local"
      Chronos::Eyintegration.register_service(@mock_backend.partner[:registration_url], base_url)
    end

    it "creates a service" do
      Chronos::Server::Service.count.should eq 1
      Chronos::Server::Service.first.url.should_not be_nil
      Chronos::Server::Service.first.state.should eq "registered"
    end

    it "can be de-registered" do
      #TODO
    end
  end

end