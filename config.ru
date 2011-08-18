require 'rubygems'
require 'bundler'
Bundler.setup


if ENV["RAILS_ENV"] == "production"
  LISONJA_DB_CREDS = YAML::load_file(File.expand_path("../config/database.yml", __FILE__))["production"]
elsif ENV["RAILS_ENV"] == "demo"
  LISONJA_DB_CREDS = YAML::load_file(File.expand_path("../config/database.yml", __FILE__))["demo"]
else
  LISONJA_DB_CREDS = {
     :adapter => "sqlite3", 
     :database => File.expand_path("../tmp/lisonja-dev.sqlite3", __FILE__)
  }
end

$:.unshift File.expand_path("../lib", __FILE__)
require 'lisonja'

Lisonja.setup!
run Lisonja::Application