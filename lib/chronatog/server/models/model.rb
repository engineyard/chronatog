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

      def self.reset!
        decendants.each do |model_class| 
          model_class.reset_column_information
          const_name = model_class.to_s.split("::").last.to_sym
          if Chronatog::Server.const_defined?(const_name)
            Chronatog::Server.send(:remove_const, const_name)
          end
        end
        @decendants = []
      end
      def self.decendants
        @decendants ||= []
      end
      def self.inherited(klass)
        decendants << klass
      end

    end
  end
end
