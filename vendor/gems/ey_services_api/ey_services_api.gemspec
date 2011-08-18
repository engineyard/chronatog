# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ey_services_api/version"

Gem::Specification.new do |s|
  s.name        = "ey_services_api"
  s.version     = EY::ServicesAPI::VERSION
  s.authors     = ["Thorben Schröder & Jacob Burkhart"]
  s.email       = ["tschroder@engineyard.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "ey_services_api"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_development_dependency 'rspec'
  s.add_dependency 'json'
  s.add_dependency 'ey_api_hmac'
end
