require File.join( File.dirname(__FILE__), "spec_helper" )

describe "creating a job" do

  describe "I have credentials" do
    before do
      @customer = Chronos::Server::Customer.create!(:name => "some-customer")
      scheduler = @customer.schedulers.create!
      Chronos::Client.setup!("http://chronos.local/chronosapi/1/jobs", scheduler.auth_username, scheduler.auth_password)
    end

    describe "client mocked to talk to in-mem rack server" do
      before do
        Chronos::Client.connection.backend = Chronos::Server::Application
      end

      describe "I create a job" do
        before do
          Chronos::Client.connection.create_job("http://example.local/my/callback/url", "*/2 * * * *") #callback every 2 minutes
        end

        it "should show in my job list" do
          jobs = Chronos::Client.connection.list_jobs
          jobs.size.should eq 1
          jobs.first['callback_url'].should eq "http://example.local/my/callback/url"
          jobs.first['schedule'].should eq "*/2 * * * *"
        end
      end

    end

  end

end