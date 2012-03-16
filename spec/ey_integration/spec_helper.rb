require 'chronatog/ey_integration'

class EyIntegrationTestHelper

  def app
    Chronatog::EyIntegration.app
  end

  def extra_middlewares
    Proc.new do
      use DocHelper::RequestLogger
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
    Chronatog::EyIntegration.connection.backend = tresfiestas_rackapp
  end

end

shared_context "ey integration reset" do
  before(:each) do
    EY::ServicesAPI.enable_mock!(@test_helper)
    @mock_backend = EY::ServicesAPI.mock_backend
    Capybara.app = @mock_backend.app
  end
end

require 'capybara/rspec'
RSpec.configure do |config|
  config.include(Capybara::RSpecMatchers)
  config.include(Capybara::DSL)
  config.before(:each) do
    @test_helper = EyIntegrationTestHelper.new
    Capybara.app = Chronatog::EyIntegration.app
  end
  config.after(:each) do
    unless DocHelper::RequestLogger.request_recordians.empty?
      raise "Missed: " + DocHelper::RequestLogger.request_recordians.inspect
    end
  end
end