require 'chronos/server'
require 'chronos/client'
require File.join( File.dirname(__FILE__), "../doc_helper" )

shared_context "chronos server reset" do
  before(:each) do
    Chronos::Server.reset!
    ActiveRecord::Base.descendants.each(&:reset_column_information)
  end
end
