require 'chronos/ey_integration/models/schema'
require 'chronos/ey_integration/models/creds'
require 'chronos/ey_integration/models/service'
require 'chronos/ey_integration/models/customer_extensions'
require 'chronos/ey_integration/models/scheduler_extensions'

Chronos::Server::Customer.send(:include, Chronos::EyIntegration::CustomerExtensions)
Chronos::Server::Scheduler.send(:include, Chronos::EyIntegration::SchedulerExtensions)
