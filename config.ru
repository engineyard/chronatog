require 'rubygems'
require 'bundler'
Bundler.setup

if rails_env = ENV["RAILS_ENV"]
  CHRONOS_DB_CREDS = YAML::load_file(File.expand_path("../config/database.yml", __FILE__))[rails_env]
  adapter = CHRONOS_DB_CREDS['adapter']
  username = CHRONOS_DB_CREDS['username']
  password = CHRONOS_DB_CREDS['password']
  host = CHRONOS_DB_CREDS['host']
  database = CHRONOS_DB_CREDS['database']
  ENV["DATABASE_URL"] = "#{adapter}://#{username}:#{password}@#{host}/#{database}"
end

$:.unshift File.expand_path("../lib", __FILE__)
require 'chronatog/ey_integration'

Chronatog::EyIntegration.setup!


class ExceptionLogging
  def initialize(app, logger)
    @app = app
    @logger = logger
  end
  def call(env)
    @app.call(env)
  rescue => e
    @logger.write(env.inspect)
    @logger.write("\n\n")
    @logger.write(e.inspect)
    @logger.write(e.backtrace.join("\n"))
    @logger.write("\n\n")
    [500, {'Content-Type' => 'text/html'}, ["500: see log/chronatog.log"]]
  end
end

log_dir = 'log'
FileUtils.mkdir_p(log_dir)
logger = File.open(log_dir + "/chronatog.log", 'a')
logger.sync = true

use Rack::CommonLogger, logger
use ExceptionLogging, logger
run Chronatog::EyIntegration.app
