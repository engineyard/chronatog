require 'sinatra/base'
require 'json'
require 'yaml'
require 'haml'
require 'chronatog/server/models'
require 'chronatog/server/application'

module Chronatog
  module Server

    def self.ensure_tmp_dir
      require 'fileutils'
      FileUtils.mkdir_p(File.expand_path("../../../tmp/", __FILE__))
      FileUtils.mkdir_p(File.expand_path("../../../config/", __FILE__))
    end

    def self.setup!
      ensure_tmp_dir
      Schema.setup!
    end

    def self.teardown!
      ensure_tmp_dir
      Schema.teardown!
    end

    def self.reset!
      teardown!
      setup!
    end

  end
end