source 'http://rubygems.org'

gem 'activerecord', '3.0.9'
gem 'haml'
gem 'sinatra'
gem 'sqlite3'

if File.exists?(File.expand_path('../vendor', __FILE__))
  path_prefix = "vendor"
elsif File.exists?(File.expand_path('../../../vendor', __FILE__))
  path_prefix = "../../vendor"
else
  raise "no suitable path for ey_* gems"
end

gem 'ey_api_hmac', :path => "#{path_prefix}/ey_api_hmac"
gem 'ey_services_api_internal', :path => "#{path_prefix}/ey_services_api_internal"
gem 'ey_services_api', :path => "#{path_prefix}/ey_services_api"
