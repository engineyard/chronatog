require 'rubygems'
require 'bundler'
Bundler.setup


if ENV["RAILS_ENV"] == "demo"
  ENV["URL_FOR_LISONJA"] = "http://lisonja.tresfiestas-demo.engineyard.com"

  LISONJA_DB_CREDS = YAML::load_file(File.expand_path("../config/database.yml", __FILE__))["demo"]
else
  ENV["URL_FOR_LISONJA"] = "http://lisonja.dev"

  LISONJA_DB_CREDS = {
     :adapter => "sqlite3", 
     :database => File.expand_path("../tmp/lisonja-dev.sqlite3", __FILE__)
  }
end

$:.unshift File.expand_path("../lib", __FILE__)
require 'lisonja'

Lisonja.reset!
run Lisonja::Application