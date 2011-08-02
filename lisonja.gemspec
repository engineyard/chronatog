Gem::Specification.new do |s|
  s.name        = "lisonja"
  s.version     = "0.1.TODO"
  s.authors     = ["Jacob & Others"]
  s.email       = ["jacob@engineyard.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "lisonja"

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
