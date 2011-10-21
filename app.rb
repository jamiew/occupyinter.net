require 'rubygems'
require 'bundler'
Bundler.require
require 'digest/sha1'
require 'logger'

configure do |config|
  Sinatra::Application.register Sinatra::RespondTo

  set :sessions, true
  set :redis, ENV['REDISTOGO_URL'] || 'redis://localhost:6379/1' # TODO smarter db number, or namespace
  set :redis_settings, {:logger => Logger.new(STDOUT)} # FIXME doesn't see to work?
end

# before do
#   puts
#   puts "*** [#{Time.now.strftime('%m-%d-%Y %h:%m:%ms')}] #{request.url} #{params.inspect}"
# end

not_found do
  @title ||= '404 File Not Found'
  @error ||= 'Sorry, but the page you were looking for could not be found.'

  respond_to do |format|
    format.html { haml :not_found, 404 }
    format.json { halt 404, {:message => @error}.to_json }
  end
end

error do
  err = request.env['sinatra.error'].message
  err ||= 'An unknown error has occured.'
  respond_to do |format|
    format.html { halt 500, err }
    format.json { halt 500, {:message => @error}.to_json }
  end
end

helpers do
  def commify(n)
    n.to_s =~ /([^\.]*)(\..*)?/
    int, dec = $1.reverse, $2 ? $2 : ""
    while int.gsub!(/(,|\.|^)(\d{3})(\d)/, '\1\2,\3')
    end
    int.reverse + dec
  end
end

def last_modified_from(files)
  filemtimes = files.map{|file| File.mtime([settings.root, file].join('/')) }
  filemtimes.last
end

UUID_SALT = "f-a9sjql23knfieu082FJlkmf__wraw34-("
def request_uuid
  inputs = [request.ip, request.user_agent, UUID_SALT]
  Digest::SHA1.hexdigest(inputs.join('_'))
end

def record_hit
  domain = request.referrer || params['url'] # TODO normalize these urls
  if domain.nil? || domain.empty?
    puts "No HTTP_REFERER or ?url param, skipping"
  else
    domain = "http://#{domain}" unless domain =~ /^http/
    uri = Addressable::URI.parse(domain)
    host = uri.host
    host = host.gsub(/^www\./, '')

    # Hack to allow FAT's /occupy/ service as their own domains
    host = [uri.host, uri.path].join if uri.host == 'fffff.at' && uri.path =~ /^\/occupy\//

    new_record = redis.setnx("site/#{host}/created_at", Time.now)
    if new_record
      puts "NEW PROTEST SITE! #{host.inspect}"
      redis.sadd("sites", host)
      redis.setnx("site/#{host}/domain", domain)
    end

    hits = redis.incr("site/#{host}/hits")

    redis.sadd("site/#{host}/uuids", request_uuid)
    uniques = redis.scard("site/#{host}/uuids")

    puts "[#{Time.now.strftime('%m-%d-%Y %h:%m:%ms')}] embed.js: host=#{host} hits=#{hits} uniques=#{uniques} referrer=#{domain}"
  end
end

# -------------------------

get "/" do
  respond_to do |format|
    format.html {
      output = haml :frontpage
      etag(Digest::SHA1.hexdigest(output))
      # last_modified(last_modified_from(["views/frontpage.html.haml", "views/socialmedia.html.erb", "views/stats.html.erb"])
      response['Cache-Control'] = "public, max-age=60"
      output
    }
  end
end

get "/embed" do
  respond_to do |format|
    format.js {
      record_hit

      content_type :html # so it renders embed.html; :format => :html does not work. WTF such a hack
      widget = erb :embed
      output = "document.write(#{widget.to_json});"

      etag(Digest::SHA1.hexdigest(output))
      # last_modified(File.mtime("#{settings.root}/views/widget.html.erb"))
      # response['Cache-Control'] = "public, max-age=60"
      response['Cache-Control'] = "private, max-age=0, must-revalidate"

      content_type :js
      output
    }
  end
end

get "/avatars" do
  # last_modified(File.mtime("#{settings.root}/views/widget.html.erb"))
  response['Cache-Control'] = "public, max-age=60"

  respond_to do |format|
    format.json {
      # FIXME avatars should just be in a ruby method, not in a view that
      # gets reparsed depending on context
      content_type :html
      r = erb(:'_avatars').split("\n").reject{|r|
        s = r.gsub(/\s/m, '').gsub(/(\/\/.*)/, '')
        (s == '')
      }.join("")

      avatars = '['+ r +']'
      content_type :json

      avatars = "#{params[:callback]}(#{avatars})" unless params[:callback].nil? || params[:callback] == ''
      etag(Digest::SHA1.hexdigest(avatars))
      avatars
    }
    format.js {
      content_type :html
      avatars = erb :avatars
      content_type :js

      etag(Digest::SHA1.hexdigest(avatars))
      avatars
    }

  end
end

get "/demo" do
  @title = "Demo"
  real_url = params[:url] && params[:url].split('?')[1]
  %{<script type="text/javascript" src="/embed.js#{real_url && "?"+real_url}"></script>}
end

get "/stats" do
  @title = "Site Stats"
  hosts = redis.smembers('sites')
  host_keys = hosts.map{|host| "site/#{host}/hits" }
  # hits = redis.mget(host_keys) # FIXME not working?
  hits = host_keys.map{|k| redis.get(k) }
  uniques = hosts.map{|host| redis.scard("site/#{host}/uuids") }
  @sites = hosts.zip(hits, uniques).sort_by{|k,v,u| v.to_i }.reverse # TODO switch to unique sorting

  respond_to do |format|
    format.html { haml :stats }
  end
end


