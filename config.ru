require 'rubygems'
require 'bundler'
Bundler.setup

ENV["URL_FOR_LISONJA"] = "http://lisonja.dev"
ENV['LISONJA_ENV'] = "dev"

$:.unshift File.expand_path("../lib", __FILE__)
require 'lisonja'

Lisonja.reset!
run Lisonja::Application