require File.join( File.dirname(__FILE__), "../spec_helper" )

describe "customers" do
  include_context "ey integration reset"

  context "with the service registered" do
    before do
      Chronatog::EyIntegration.register_service(@mock_backend.partner[:registration_url], @test_helper.base_url)
    end

    describe "when EY sends a service account creation request" do
      before do
        @mock_backend.service
        DocHelper::RequestLogger.record_next_request('service_account_creation_url', 
                                                     'service_account_creation_params', 
                                                     'service_account_creation_response')
        @service_account = @mock_backend.service_account
      end

      it "creates a customer" do
        Chronatog::Server::Customer.count.should eq 1
        created_customer = Chronatog::Server::Customer.first
        DocHelper.save("customer_creation_created_customer", created_customer)
        #TODO: assert more on the customer ?
      end

      describe "visiting over SSO" do
        before do
          @configuration_url = @service_account[:pushed_service_account][:configuration_url]
          DocHelper.save("service_configuration_url", @configuration_url)

          params = {
            'timestamp' => Time.now.iso8601,
            'ey_user_id' => 123,
            'ey_user_name' => "Person Name",
            'ey_return_to_url' => "https://cloud.engineyard.com/dashboard",
            'access_level' => 'owner',
          }
          signed_configuration_url = EY::ApiHMAC::SSO.sign(@configuration_url, 
                                                           params, 
                                                           @service_account[:service][:partner][:auth_id], 
                                                           @service_account[:service][:partner][:auth_key])

          DocHelper.save("service_configuration_url_signed", signed_configuration_url)

          visit signed_configuration_url
        end

        it "logs you into Chronatog" do
          visit @configuration_url
          page.status_code.should eq 200
        end

        it "works" do
          page.status_code.should eq 200
          page.find("#current_plan").text.strip.should eq "Freemium"
        end

        it "let's you select the freemium plan" do
          within("#plan_selection") do
            select "Freemium"
            click_button "Change Plan"
          end
          page.status_code.should eq 200
          page.find("#current_plan").text.strip.should eq "Freemium"
        end

        it "let's you select the OMG IT'S SO AWESOME plan" do
          within("#plan_selection") do
            select "OMG IT'S SO AWESOME"
            click_button "Change Plan"
          end
          page.status_code.should eq 200
          page.find("#current_plan").text.strip.should eq "OMG IT'S SO AWESOME"
        end

        describe "when you go back to AWSM" do
          before do
            click_link "Go Back to EngineYard Cloud"
          end

          it "works" do
            page.status_code.should eq 200
            page.body.should match "Hello this is fake AWSM dashboard"
          end

          it "logs you out of Chronatog" do
            visit @configuration_url
            page.status_code.should eq 401
          end

        end
      end

      it "can handle a delete" do
        @mock_backend.destroy_service_account
        Chronatog::Server::Customer.count.should eq 0
      end

      describe "with some usage" do
        before do
          @mock_backend.provisioned_service
          @customer = Chronatog::Server::Customer.last
          @customer.plan_type = "awesome"
          @customer.created_at = (@customer.created_at - 1.day)
          @customer.save!
          scheduler = @customer.schedulers.first
          scheduler.usage_calls = 5
          scheduler.save!
        end

        it "can send a bill" do
#{bill_all_call{
          Chronatog::Server::Customer.all.each(&:bill!)
#}bill_all_call}
        end

        it "sends a bill on delete" do
          DocHelper::RequestLogger.record_next_request('service_account_delete_url')
          DocHelper::RequestLogger.record_next_request('final_bill_url', 'final_bill_params')
          @mock_backend.destroy_service_account
          DocHelper.snippets['final_bill_url'].should eq @customer.invoices_url
          lambda{ @customer.reload }.should raise_error(ActiveRecord::RecordNotFound)
        end

      end

    end

  end

end