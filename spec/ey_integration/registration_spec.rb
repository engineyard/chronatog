require File.join( File.dirname(__FILE__), "spec_helper" )

describe "setup" do
  include_context "ey integration reset"

  it "can fetch listing of services" do
    result = Chronos::EyIntegration.connection.list_services(@mock_backend.partner[:registration_url])
    result.should eq []
  end

  describe "with the service registered" do
    before do
      # Chronos::EyIntegration.save_creds(@mock_backend.partner[:auth_id], @mock_backend.partner[:auth_key])
      base_url = "http://chronos.local"
      @service = Chronos::EyIntegration.register_service(@mock_backend.partner[:registration_url], base_url)
    end

    it "creates a service" do
      Chronos::Server::Service.count.should eq 1
      @service.should eq Chronos::Server::Service.first
      @service.url.should_not be_nil
      @service.state.should eq "registered"
      @service.name.should eq "Chronos"
    end

    it "can be de-registered" do
      pending
    end
  end

end