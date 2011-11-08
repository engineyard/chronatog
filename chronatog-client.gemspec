# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "chronatog/client/version"

Gem::Specification.new do |s|
  s.name        = "chronatog-client"
  s.version     = Chronatog::Client::VERSION
  s.authors     = ["Jacob Burkhart & Josh Lane & Others"]
  s.email       = ["jacob@engineyard.com"]
  s.homepage    = "http://chronatog.engineyard.com"
  s.summary     = "Client for Chronatog: Web cron as a service."
  s.description = "Client for Chronatog: Web cron as a service. See git repo for more details: https://github.com/engineyard/chronatog"

  s.files         = ["lib/chronatog/client.rb", "lib/chronatog/client/version.rb"]
  s.require_paths = ["lib"]

  s.add_dependency 'rack-client'
  #JSON is an implicit dependency
end
