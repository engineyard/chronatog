source 'http://rubygems.org'

#REMOVE ME BEFORE COMMITTING
gem 'ey_services_api', :path => "../ey_services_api"
gem 'cubbyhole', :path => "../cubbyhole"

#FIXME
gem 'ey_services_fake', :path => "../ey_services_fake"
gem 'ey_api_hmac', :path => "../ey_api_hmac"

gemspec :name => "chronatog"

gem 'pg' #Database for production

group :test, :development do
  #for documentation generation
  gem 'RedCloth'
  gem 'colored'

  #for tests
  gem 'guard-rspec'
  gem 'sqlite3' #Database for tests
  gem 'rspec'

  gem 'rake'
end
