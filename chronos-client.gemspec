# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "chronos/client/version"

Gem::Specification.new do |s|
  s.name        = "chronos"
  s.version     = Chronos::Client::VERSION
  s.authors     = ["Jacob Burkhart & Josh Lane & Others"]
  s.email       = ["jacob@engineyard.com"]
  s.homepage    = "http://chronos.engineyard.com"
  s.summary     = "Client for Chronos: Web cron as a service."
  s.description = "Client for Chronos: Web cron as a service."

  s.files         = ["lib/chronos/client.rb", "lib/chronos/client/version.rb"]
  s.require_paths = ["lib"]

  s.add_dependency 'rack-client'
end
