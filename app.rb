require 'rubygems'
require 'sinatra'

configure do |config|
  set :sessions, true

  ROOT = File.expand_path(File.dirname(__FILE__))

  %w(haml sinatra/respond_to configatron json dm-core dm-types dm-timestamps dm-aggregates dm-ar-finders dm-validations).each{|lib| require lib}
  %w(lib/helpers lib/actions models/site models/visit).each{|lib| require "#{ROOT}/#{lib}"}

  Rack::MethodOverride # FOR PUT METHOD
  Sinatra::Application.register Sinatra::RespondTo

  configatron.configure_from_yaml("#{ROOT}/settings.yml", :hash => Sinatra::Application.environment.to_s)

  DataMapper::Logger.new(STDOUT, :debug)
  DataMapper.setup(:default, configatron.db_connection.gsub(/ROOT/, ROOT))
  DataMapper.auto_upgrade!
end


# 404 errors
not_found do
  @title ||= 'Where\'d it go!?'
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
end