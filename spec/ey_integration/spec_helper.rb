require 'chronatog/ey_integration'
require File.join( File.dirname(__FILE__), "../doc_helper" )

class EyIntegrationTestHelper
  def app
    Chronatog::EyIntegration.app
  end

  def base_url
    "http://chronatog.example.com"
  end

  def reset!
    #TODO
  end

  def setup(*args)
    puts "setup #{args.inspect}"
  end

end

shared_context "ey integration reset" do
  before(:each) do
    Chronatog::EyIntegration.reset!
    EY::ServicesAPI.enable_mock!(EyIntegrationTestHelper.new)
    @mock_backend = EY::ServicesAPI.mock_backend
    # @mock_backend.connection_to_partner.backend = Chronatog::EyIntegration.app
  end
end