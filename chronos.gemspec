Gem::Specification.new do |s|
  s.name        = "chronos"
  s.version     = "0.0.0"
  s.authors     = ["Jacob Burkhart & Josh Lane & Others"]
  s.email       = ["jacob@engineyard.com"]
  s.homepage    = "http://chronos.engineyard.com"
  s.summary     = "Web cron as a service. Engine Yard's partner integration example."
  s.description = "Web cron as a service. Only has a gemspec so that other project can easily require for tests."

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency 'activerecord'
  s.add_dependency 'haml'
  s.add_dependency 'sinatra'
  s.add_dependency 'ey_services_api'
  s.add_dependency 'rufus-scheduler'
end
