require File.join( File.dirname(__FILE__), "../spec_helper" )

describe Chronatog::Client do

  describe "faked" do
    before do
      @previous_dir = `pwd`.strip
      Dir.chdir(Dir.tmpdir)
      @tmpdir = `pwd`.strip
    end

    after do
      Dir.chdir(@previous_dir)
    end

    describe "I have ey_services_config_local.yml" do
      before do
        faked_config = {
          'chronatog' => {
            'service_url'   => 'in-memory',
            'auth_username' => '123-ignored',
            'auth_password' => '456-also-ignored',
          }
        }
        DocHelper.save('ey_services_config_local_yaml_contents', faked_config.to_yaml)
        FileUtils.mkdir_p(File.join(@tmpdir, "config"))
        write_to_path = File.join(@tmpdir, "config", "ey_services_config_local.yml")
        File.open(write_to_path, "w+") do |fp|
          fp.write(faked_config.to_yaml)
        end
      end

      describe "Chronatog::Client after setup using EY::Config" do
        before do
          require 'ey_config'
          require 'json'
#{chronatog_setup_from_ey_config{
          @client = Chronatog::Client.setup!(EY::Config.get(:chronatog, 'service_url'), 
                                             EY::Config.get(:chronatog, 'auth_username'), 
                                             EY::Config.get(:chronatog, 'auth_password'))
#}chronatog_setup_from_ey_config}
        end

        it "can create, list, and destroy jobs" do
          job_url = @client.create_job("some_callback_url", "some_schedule")["url"]
          @client.list_jobs.should eq [{'url' => job_url, 'schedule' => "some_schedule", 'callback_url' => "some_callback_url"}]
          @client.destroy_job(job_url)
          @client.list_jobs.should eq []
        end
      end

    end
  end

end