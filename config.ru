require 'rubygems'
require 'bundler'
Bundler.setup


if ENV["RAILS_ENV"] == "production"
  CHRONOS_DB_CREDS = YAML::load_file(File.expand_path("../config/database.yml", __FILE__))["production"]
elsif ENV["RAILS_ENV"] == "demo"
  CHRONOS_DB_CREDS = YAML::load_file(File.expand_path("../config/database.yml", __FILE__))["demo"]
else
  CHRONOS_DB_CREDS = {
     :adapter => "sqlite3",
     :database => File.expand_path("../tmp/chronos-dev.sqlite3", __FILE__)
  }
end

$:.unshift File.expand_path("../lib", __FILE__)
require 'chronos'

Chronos.setup!
run Chronos::Application
