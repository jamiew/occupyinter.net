require 'rubygems'
require 'sinatra'

root_dir = File.dirname(__FILE__)

if ENV['RACK_ENV'].to_s != 'production'
  puts "Development mode..."
  set :environment, :development
  set :root,        root_dir
  disable :run

  log = File.new(root_dir + "/log/#{Sinatra::Application.environment.to_s}.log", "a+")
  STDOUT.reopen(log)
  STDERR.reopen(log)
end

require "#{root_dir}/app"
run Sinatra::Application
