require File.join( File.dirname(__FILE__), "../spec_helper" )

describe "schedulers" do
  include_context "ey integration reset"

  context "with the service registered" do
    before do
      Chronatog::EyIntegration.register_service(@mock_backend.partner[:registration_url], @test_helper.base_url)
    end

    describe "with a customer" do
      before do
        @mock_backend.service_account
        @customer = Chronatog::Server::Customer.first
      end

      describe "when provisioned" do
        before do
          DocHelper::RequestLogger.record_next_request('service_provisioning_url', 
                                                       'service_provisioning_params',
                                                       'service_provisioning_response_json')
          @mock_backend.provisioned_service
        end

        it "creates a scheduler" do
          @customer.schedulers.reload.size.should eq 1
          scheduler = @customer.schedulers.reload.first
          DocHelper.save("service_provisioning_created_scheduler", scheduler)

          scheduler.should_not be_nil
          scheduler.decomissioned_at.should be_nil
          #TODO: assert more on the scheduler?
        end

        it "can handle a delete" do
          @mock_backend.destroy_provisioned_service
          @customer.reload

          scheduler = @customer.schedulers.reload.first
          scheduler.decomissioned_at.should_not be_nil
        end
      end
    end

  end

end