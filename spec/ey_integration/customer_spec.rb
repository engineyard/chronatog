require File.join( File.dirname(__FILE__), "spec_helper" )

describe "customers" do
  before do
    @mock_backend = EY::ServicesAPI.mock_backend
  end

  context "with the service registered" do
    before do
      # Chronos::Eyintegration.save_creds(@mock_backend.partner[:auth_id], @mock_backend.partner[:auth_key])
      base_url = "http://chronos.local"
      @service = Chronos::Eyintegration.register_service(@mock_backend.partner[:registration_url], base_url)
    end

    describe "when EY sends a service account creation request" do
      before do
        @mock_backend.create_service_account
      end

      it "creates a customer" do
        @service.reload
        @service.customers.size.should eq 1
        #TODO: assert more on the customer
      end

      it "can handle a delete" do
        @mock_backend.destroy_service_account
        @service.reload
        @service.customers.size.should eq 0
      end
    end

  end

end