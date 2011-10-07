require File.join( File.dirname(__FILE__), "spec_helper" )

describe "customers" do
  include_context "ey integration reset"

  context "with the service registered" do
    before do
      Chronatog::EyIntegration.register_service(@mock_backend.partner[:registration_url], @test_helper.base_url)
    end

    describe "when EY sends a service account creation request" do
      before do
        @mock_backend.service
        DocHelper::RequestLogger.record_next_request('service_account_creation_url', 'service_account_creation_params')
        @service_account = @mock_backend.service_account
      end

      it "creates a customer" do
        Chronatog::Server::Customer.count.should eq 1
        created_customer = Chronatog::Server::Customer.first
        DocHelper.save("customer_creation_created_customer", created_customer)
        #TODO: assert more on the customer ?
      end

      it "can visit the service" do
        configuration_url = @service_account[:pushed_service_account][:configuration_url]
        DocHelper.save("service_configuration_url", configuration_url)

        params = {
          'timestamp' => Time.now.iso8601,
          'ey_user_id' => 123,
          'ey_user_name' => "Person Name",
          'ey_return_to_url' => "https://cloud.engineyard.com/accounts/123/services",
          'access_level' => 'owner',
        }
        signed_configuration_url = EY::ApiHMAC::SSO.sign(configuration_url, 
                                                         params, 
                                                         @service_account[:service][:partner][:auth_id], 
                                                         @service_account[:service][:partner][:auth_key])

        DocHelper.save("service_configuration_url_signed", signed_configuration_url)

        puts @service_account[:service][:partner][:auth_id].inspect
        puts @service_account[:service][:partner][:auth_key].inspect

        puts "signed: \n" + signed_configuration_url.inspect

        visit signed_configuration_url
        page.status_code.should eq 200
      end

      it "can handle a delete" do
        @mock_backend.destroy_service_account
        Chronatog::Server::Customer.count.should eq 0
      end
    end

  end

end