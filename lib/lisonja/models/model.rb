require 'active_record'

module Lisonja
  class Model < ActiveRecord::Base
    @abstract_class = true
    establish_connection(
      :adapter => "sqlite3",
      :database  => File.expand_path("../../../../tmp/lisonja.sqlite3", __FILE__)
    )
  end
end