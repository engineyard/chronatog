require 'ey_services_api'
require 'tresfiestas/gem_integration_test'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

shared_context "tresfiestas setup" do
  before(:all) do
    backend = Tresfiestas::GemIntegrationTest
    @tresfiestas = backend.setup!
  end

  before do
    @tresfiestas.reset!
  end
end
