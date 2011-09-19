require 'active_record'

module Chronos
  module Server
    class Model < ActiveRecord::Base
      @abstract_class = true
      establish_connection((defined?(CHRONOS_DB_CREDS) && CHRONOS_DB_CREDS) || {
        :adapter => "sqlite3",
        :database  => File.expand_path("../../../../../tmp/chronos.sqlite3", __FILE__)
      })
    end
  end
end
