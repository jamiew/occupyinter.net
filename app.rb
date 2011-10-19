require 'rubygems'
require 'sinatra'
require 'digest/sha1'

configure do |config|
  set :sessions, true

  %w(haml sinatra/respond_to json).each{|lib| require lib}

  Sinatra::Application.register Sinatra::RespondTo
  # configatron.configure_from_yaml("#{settings.root}/settings.yml", :hash => Sinatra::Application.environment.to_s)

  %w(helpers).each{|lib| require "#{settings.root}/#{lib}"}
end

# Global
before do
  puts
  puts "*** [#{Time.now.strftime('%m-%d-%Y %h:%m:%ms')}] #{request.url} #{params.inspect}"
end

# 404s
not_found do
  @title ||= '404 File Not Found'
  @error ||= 'Sorry, but the page you were looking for could not be found.'

  respond_to do |format|
    format.json { halt 404, make_json({:message => @error}) }
    format.html { haml :not_found, 404 }
  end
end

# 500s
error do
  err = request.env['sinatra.error'].message
  err ||= 'An unknown error has occured.'
  make_error(error)
end

# -------------------------

def last_modified_from(files)
  filemtimes = files.map{|file| File.mtime([settings.root, file].join('/')) }
  filemtimes.last
end

get "/" do
  respond_to do |format|
    format.html {
      output = haml :frontpage
      etag(Digest::SHA1.hexdigest(output))
      last_modified(File.mtime("#{settings.root}/views/frontpage.html.haml"))
      response['Cache-Control'] = "public, max-age=60"
      output
    }
  end
end

get "/embed" do
  content_type :html # so it renders widget.html, :format => :html does not work. WTF such a hack
  widget = erb :widget
  content_type :js

  respond_to do |format|
    format.js {
      output = "document.write(#{widget.to_json})"
      etag(Digest::SHA1.hexdigest(output))
      last_modified(File.mtime("#{settings.root}/views/widget.html.erb"))
      response['Cache-Control'] = "public, max-age=60"
      output
    }
  end
end

get "/demo" do
  real_url = params[:url] && params[:url].split('?')[1]
  puts real_url.inspect
  %{<script type="text/javascript" src="/embed.js#{real_url && "?"+real_url}"></script>}
end
