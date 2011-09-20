require 'chronos/server'
require 'chronos/client'

shared_context "chronos server reset" do
  before(:each) do
    Chronos::Server.reset!
    ActiveRecord::Base.descendants.each(&:reset_column_information)
  end
end
