require 'active_record'

module Chronatog
  module Server
    class Model < ActiveRecord::Base
      @abstract_class = true
      establish_connection(:adapter  => "sqlite3",
                           :database => File.expand_path("../../../../../tmp/chronatog.sqlite3", __FILE__))
    end
  end
end
