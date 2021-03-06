require File.join( File.dirname(__FILE__), "../spec_helper" )

describe "setup" do
  include_context "ey integration reset"

  it "can fetch listing of services" do
    registration_url = @mock_backend.partner[:registration_url]
    list_services_result =
#{list_services_call{
      Chronatog::EyIntegration.connection.list_services(registration_url)
#}list_services_call}
    DocHelper.save('list_services_result', list_services_result)
    list_services_result.should eq []
  end

  describe "with the service registered" do
    before do
#{set_chronatog_url{
      chronatog_url = "https://chronatog.engineyard.com"
#}set_chronatog_url}
      registration_url = @mock_backend.partner[:registration_url]
      DocHelper.save('registration_url', registration_url)
#{register_service_call{
      registered_service = Chronatog::EyIntegration.register_service(registration_url, chronatog_url)
#}register_service_call}
      DocHelper.save('register_service_result', registered_service)
      @service = registered_service
      DocHelper.save('service_registration_params', Chronatog::EyIntegration.service_registration_params(chronatog_url))
    end

    it "creates a service" do
      Chronatog::EyIntegration.service.should_not be_nil
    end

    it "can be deregistered"

  end

end