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
        @mock_backend.service_account
      end

      it "creates a customer" do
        Chronatog::Server::Customer.count.should eq 1
        created_customer = Chronatog::Server::Customer.first
        DocHelper.save("customer_creation_created_customer", created_customer)
        #TODO: assert more on the customer
      end

      it "can handle a delete" do
        @mock_backend.destroy_service_account
        Chronatog::Server::Customer.count.should eq 0
      end
    end

  end

end