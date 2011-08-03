require 'rubygems'
require 'bundler'
Bundler.setup

ENV["URL_FOR_LISONJA"] = "http://lisonja.dev"
require File.expand_path("../lib/lisonja", __FILE__)

Lisonja.reset!
run Lisonja::Application