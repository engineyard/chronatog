require 'spec_helper'

describe "customers" do
  before do
    @mock_backend = EY::ServicesAPI.mock_backend
  end

  context "with the service registered" do
    before do
      Chronos::Server.save_creds(@mock_backend.partner[:auth_id], @mock_backend.partner[:auth_key])
      base_url = "http://chronos.local"
      @service = Chronos::Server.register_service(@mock_backend.partner[:registration_url], base_url)
    end

    describe "with a customer" do
      before do
        @mock_backend.create_service_account
        @customer = @service.reload.customers.first
      end

      describe "when provisioned" do
        before do
          @mock_backend.create_provisioned_service
        end

        describe "creating a job" do
          before do
            provisioned_service = @mock_backend.created_provisioned_service
            provisioned_service['vars'].each do |k, v|
              ENV[k] = v
            end
            Chronos::Client.connection.backend = Chronos::Server::Application
            Chronos::Client.connection.create_job("somecallback", "someschedule")
          end

          it "works" do
            job_listing = Chronos::Client.connection.list_jobs

            pending "implement the server"
            job_listing.should eq [{:callback_url => "somecallback", :schedule => "someschedule"}]
          end
        end
      end
    end

  end

end