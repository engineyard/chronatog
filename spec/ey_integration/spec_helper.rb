require 'chronatog/ey_integration'

class HasADashboardAWSM < Sinatra::Base
  enable :raise_errors
  disable :dump_errors
  disable :show_exceptions

  get '/dashboard' do
    "Hello this is fake AWSM dashboard"
  end

end

class EyIntegrationTestHelper

  def app
    chronatog_base_url = "#{base_url}/"
    @app ||= Rack::Builder.new do
      use DocHelper::RequestLogger
      map chronatog_base_url do
        run Chronatog::EyIntegration.app
      end
      map "https://cloud.engineyard.com/" do
        run HasADashboardAWSM
      end
    end
  end

  def base_url
    "https://chronatog.engineyard.com"
  end

  def reset!
    Chronatog::EyIntegration.reset!
  end

  def setup(auth_id, auth_key, tresfiestas_url, tresfiestas_rackapp)
    Chronatog::EyIntegration.save_creds(auth_id, auth_key)
    Chronatog::EyIntegration.connection.backend = Rack::Builder.new do
      use DocHelper::RequestLogger
      map "#{tresfiestas_url}/" do
        run tresfiestas_rackapp
      end
    end
  end

end

shared_context "ey integration reset" do
  before(:each) do
    EY::ServicesAPI.enable_mock!(@test_helper)
    @mock_backend = EY::ServicesAPI.mock_backend
  end
end

require 'capybara/rspec'
RSpec.configure do |config|
  config.include(Capybara::RSpecMatchers)
  config.include(Capybara::DSL)
  config.before(:each) do
    @test_helper = EyIntegrationTestHelper.new
    Capybara.app = @test_helper.app
  end
  config.after(:each) do
    unless DocHelper::RequestLogger.request_recordians.empty?
      raise "Missed: " + DocHelper::RequestLogger.request_recordians.inspect
    end
  end
end