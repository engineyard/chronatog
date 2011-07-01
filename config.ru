require 'rubygems'
require 'bundler'
Bundler.setup

ENV["URL_FOR_LISONJA"] = "http://lisonja.dev"
require File.expand_path("../lisonja", __FILE__)

Lisonja.reset!
# Lisonja.seed_data
run Lisonja