require 'rubygems'
require 'sinatra'
require 'sinatra/redis'
require 'digest/sha1'

configure do |config|
  set :sessions, true

  # TODO namespace all redis calls, or pick a genuinely unique DB number
  set :redis, ENV['REDISTOGO_URL'] || 'redis://localhost:6379/1'

  ROOT = File.expand_path(File.dirname(__FILE__))

  %w(haml sinatra/respond_to configatron json dm-core dm-types dm-timestamps dm-aggregates dm-ar-finders dm-validations).each{|lib| require lib}

  Rack::MethodOverride # FOR PUT METHOD
  Sinatra::Application.register Sinatra::RespondTo

  configatron.configure_from_yaml("#{ROOT}/settings.yml", :hash => Sinatra::Application.environment.to_s)

  %w(lib/helpers lib/actions models/site models/visit models/user).each{|lib| require "#{ROOT}/#{lib}"}
  # DataMapper::Logger.new(STDOUT, :debug) unless ENV['RACK_ENV'] == 'production'
  DataMapper.setup(:default, ENV["DATABASE_URL"] || configatron.db_connection.gsub(/ROOT/, ROOT))
  DataMapper.auto_upgrade!
end


# 404 errors
not_found do
  @title ||= '404 File Not Found'
  @error ||= 'Sorry, but the page you were looking for could not be found.'

  respond_to do |format|
    format.json { halt 404, make_json({:message => @error}) }
    format.html { haml :not_found, 404 }
  end
end

# 500 errors
error do
  err = request.env['sinatra.error'].message
  err ||= 'An unknown error has occured.'
  make_error(error)
end


# Require before
before do
  puts
  puts "*** [#{Time.now.strftime('%m-%d-%Y %h:%m:%ms')}] #{request.url} #{params.inspect}"
end
