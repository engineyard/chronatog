require 'active_record'

module Chronatog
  module Server
    class Model < ActiveRecord::Base
      CONNECTION_ARGS = (defined?(CHRONOS_DB_CREDS) && CHRONOS_DB_CREDS) || {
        :adapter  => "sqlite3",
        :database => File.expand_path("../../../../../tmp/chronatog.sqlite3", __FILE__)
      }
      @abstract_class = true
      establish_connection(CONNECTION_ARGS)

      #WORKAROUND fix for bug in AR 3.1 (https://github.com/rails/rails/pull/3240)
      unless ActiveRecord::Base.connected?
        ActiveRecord::Base.establish_connection(CONNECTION_ARGS)
      end

    end
  end
end
