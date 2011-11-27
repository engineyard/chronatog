source 'http://rubygems.org'

#Wish we could call gemspec here, but if we do, deploy fails with "You have modified your Gemfile in development but did not check"
gem 'activerecord'
gem 'haml'
gem 'sinatra', :require => 'sinatra/base'
gem 'ey_services_api', ">=0.2.0"
gem 'ey_api_hmac'

gem 'pg' #Database for production

group :test, :development do
  #for documentation generation
  gem 'RedCloth'
  gem 'colored'

  #for tests
  gem 'ey_services_fake', ">=0.1.0"
  gem 'guard-rspec'
  gem 'sqlite3' #Database for tests
  gem 'rspec'
  gem 'capybara'
  gem 'ey_config'

  gem 'rake'
end
