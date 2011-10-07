require 'chronatog/server'
require 'chronatog/client'
require File.join( File.dirname(__FILE__), "../doc_helper" )

shared_context "chronatog server reset" do
  before(:each) do
    Chronatog::Server.reset!
    Chronatog::Server::Model.reset!
    load File.expand_path('lib/chronatog/server/models/customer.rb')
    load File.expand_path('lib/chronatog/server/models/scheduler.rb')
    load File.expand_path('lib/chronatog/server/models/job.rb')
  end
end
