source 'https://rubygems.org'

ruby '2.7.6'

gem 'sinatra', '1.2.6'
gem 'rack', '1.3.3' # silence _WKV warning
gem 'haml', '3.1.2'
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
