source 'https://rubygems.org'

ruby '2.1.3'

gem 'sinatra', '1.2.6'
gem 'rack', '1.3.3' # silence _WKV warning
gem 'haml', '5.0.0'
gem 'sinatra-respond_to', '0.7.0', :require => 'sinatra/respond_to'
gem 'redis', '~> 2.2'
gem 'sinatra-redis', :require => 'sinatra/redis'
gem 'addressable', :require => 'addressable/uri'
gem 'dalli'

group :development, :test do
  gem 'shotgun'
  gem 'wirble'
end

group :test do
  gem 'rspec', '2.6.0'
  gem 'rack-test', '0.6.0'
end
