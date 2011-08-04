require 'rubygems'
require 'bundler'
Bundler.setup

ENV["URL_FOR_LISONJA"] = "http://lisonja.dev"
ENV['LISONJA_ENV'] = "dev"
require 'lisonja'

Lisonja.reset!
run Lisonja::Application