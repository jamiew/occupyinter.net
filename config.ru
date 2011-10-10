require 'rubygems'
require 'sinatra'

root_dir = File.dirname(__FILE__)

=begin
set :environment, :development
set :root,        root_dir
set :app_file,    File.join(root_dir, 'app.rb')
disable :run

log = File.new(root_dir + "/log/#{Sinatra::Application.environment.to_s}.log", "a+")
STDOUT.reopen(log)
STDERR.reopen(log)
=end

require "#{root_dir}/app"
run Sinatra::Application
