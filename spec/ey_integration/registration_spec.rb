require File.join( File.dirname(__FILE__), "spec_helper" )

describe "setup" do
  include_context "ey integration reset"

  it "can fetch listing of services" do
    list_services_result =
#{list_services_call{
      Chronatog::EyIntegration.connection.list_services(@mock_backend.partner[:registration_url])
#}list_services_call}
    DocHelper.save('list_services_result', list_services_result.inspect)
    list_services_result.should eq []
  end

  describe "with the service registered" do
    before do
      # Chronatog::EyIntegration.save_creds(@mock_backend.partner[:auth_id], @mock_backend.partner[:auth_key])
      base_url = "http://chronatog.local"
      @service = Chronatog::EyIntegration.register_service(@mock_backend.partner[:registration_url], base_url)
    end

    it "creates a service" do
      Chronatog::Server::Service.count.should eq 1
      @service.should eq Chronatog::Server::Service.first
      @service.url.should_not be_nil
      @service.state.should eq "registered"
      @service.name.should eq "Chronatog"
    end

    it "can be de-registered" do
      pending
    end
  end

end