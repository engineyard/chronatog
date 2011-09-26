require 'chronatog/server'
require 'chronatog/client'
require File.join( File.dirname(__FILE__), "../doc_helper" )

shared_context "chronatog server reset" do
  before(:each) do
    Chronatog::Server.reset!
    ActiveRecord::Base.descendants.each(&:reset_column_information)
  end
end
