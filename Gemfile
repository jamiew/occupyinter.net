source :rubygems

gem "sinatra",              "1.2.6"
gem "configatron",          "2.8.0"
gem "haml",                 "3.1.2"
gem "json",                 "1.4.6"
gem "sinatra-respond_to",   "0.7.0"

gem "data_objects",         "0.10.2"
gem "do_mysql",             "0.10.2"
gem "dm-core",              "0.10.2"
gem "dm-aggregates",        "0.10.2"
gem "dm-ar-finders",        "0.10.2"
gem "dm-timestamps",        "0.10.2"
gem "dm-types",             "0.10.2"
gem "dm-validations",       "0.10.2"

group :development do
  gem "shotgun"
end

group :development, :test do
  gem "do_sqlite3",         :require => false
end

group :test do
  gem "rspec",              "2.6.0"
  gem "rack-test",          "0.6.0"
end

group :production do
  gem "do_postgres", :require => false
end
