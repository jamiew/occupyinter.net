source 'https://rubygems.org'

ruby '2.7.6'

gem 'sinatra'
gem 'sinatra-contrib' # for sinatra/respond_with
gem 'rack'
gem 'haml'
gem 'redis'
gem 'sinatra-redis', require: 'sinatra/redis'
gem 'addressable', require: 'addressable/uri'
gem 'dalli'

group :development, :test do
  gem 'shotgun'
  gem 'wirble'
end

group :test do
  gem 'rspec'
  gem 'rack-test'
end
