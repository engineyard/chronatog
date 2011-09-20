require File.join( File.dirname(__FILE__), "spec_helper" )

describe "creating a job" do

  describe "I have credentials" do
    before do
      @customer = Chronos::Server::Customer.create!(:name => "some-customer")
      scheduler = @customer.schedulers.create!
      @client = Chronos::Client.setup!("http://chronos.local/chronosapi/1/jobs", scheduler.auth_username, scheduler.auth_password)
    end

    describe "client mocked to talk to in-mem rack server" do
      before do
        @client.backend = Chronos::Server::Application
      end

      describe "I create a job" do
        before do
          @job = @client.create_job("http://example.local/my/callback/url", "*/2 * * * *") #callback every 2 minutes
        end

        it "works" do
          @job['callback_url'].should eq "http://example.local/my/callback/url"
          @job['schedule'].should eq "*/2 * * * *"
        end

        it "should show in my job list" do
          jobs = @client.list_jobs
          jobs.size.should eq 1
          jobs.first['callback_url'].should eq "http://example.local/my/callback/url"
          jobs.first['schedule'].should eq "*/2 * * * *"
        end

        it "should be GET-able" do
          job = @client.get_job(@job["url"])
          job.should eq @job
        end

        describe "I delete the job" do
          before do
            @client.destroy_job(@job["url"])
          end

          it "should be gone" do
            jobs = @client.list_jobs
            jobs.size.should eq 0
          end
        end

      end

    end

  end

end