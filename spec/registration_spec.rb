require 'spec_helper'

describe "setup" do
  before do
    @mock_backend = EY::ServicesAPI.mock_backend
  end

  describe "with the service registered" do
    before do
      Chronos.save_creds(@mock_backend.partner[:auth_id], @mock_backend.partner[:auth_key])
      base_url = "http://chronos.local"
      Chronos.register_service(@mock_backend.partner[:registration_url], base_url)
    end

    it "creates a service" do
      Chronos::Service.count.should eq 1
      Chronos::Service.first.url.should_not be_nil
      Chronos::Service.first.state.should eq "registered"
    end

    it "can be de-registered" do
      #TODO
    end
  end

end