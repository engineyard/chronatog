Gem::Specification.new do |s|
  s.name        = "chronos"
  s.version     = "0.1.TODO"
  s.authors     = ["Jacob & Others"]
  s.email       = ["jacob@engineyard.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Web cron as a service.}
  s.description = %q{TODO: Web cron as a service. Engine Yard's partner integration example.}

  s.rubyforge_project = "chronos"

  s.files         = `git ls-files`.split("\n")
  # s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  # s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'activerecord', '3.0.9'
  s.add_dependency 'ey_sso'
  s.add_dependency 'haml'
  s.add_dependency 'sinatra'
  s.add_dependency 'sqlite3'
end
