require 'rubygems'
require 'bundler'
Bundler.setup

if rails_env = ENV["RAILS_ENV"]
  CHRONOS_DB_CREDS = YAML::load_file(File.expand_path("../config/database.yml", __FILE__))[rails_env]
end

$:.unshift File.expand_path("../lib", __FILE__)
require 'chronos/ey_integration'

Chronos::EyIntegration.setup!
run Chronos::EyIntegration.app
