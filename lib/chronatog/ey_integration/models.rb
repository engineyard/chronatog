require 'chronatog/ey_integration/models/schema'
require 'chronatog/ey_integration/models/customer_extensions'
require 'chronatog/ey_integration/models/scheduler_extensions'

Chronatog::Server::Customer.send(:include, Chronatog::EyIntegration::CustomerExtensions)
Chronatog::Server::Scheduler.send(:include, Chronatog::EyIntegration::SchedulerExtensions)

module Chronatog::EyIntegration
  class EyCredentials < Chronatog::Server::Model
  end
  class EyService < Chronatog::Server::Model
  end
end
