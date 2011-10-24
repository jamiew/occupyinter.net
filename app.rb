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

def debug(msg)
  return if prod?
  puts msg
end

before do
  debug ""
  debug "*** [#{Time.now.strftime('%m-%d-%Y %h:%m:%ms')}] #{request.url} #{params.inspect}"
end

not_found do
  @title ||= '404 File Not Found'
  @error ||= 'Sorry, but the page you were looking for could not be found.'

  respond_to do |format|
    format.html { halt 404, "404 File Not Found"  }
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

  def prod?
    ENV['RACK_ENV'].to_s == 'production'
  end

  def dev?
    !prod?
  end

  # TODO fill with all our avatars
  def raw_avatars
    [
    "banana-evanroth-occupy.gif",
    "jig-evanroth-occupy.gif",
    "gdance-evanroth-occupy.gif",
    "david_goliath-evanroth-stevelambert-occupy.gif",
    "bugs_troll_mrqmarx.gif",
    "hallo-surfer_dragan.gif",
    "jesus-evanroth-occupy.gif",
    # "Hombre-65_gyna.gif",
    "moonwalk-evanroth-occupy.gif",
    "jeanluc-evanroth-occupy.gif",
    "occupy-net-evanroth-02.gif",
    "headless-evanroth-occupy.gif",
    # "weare99percent_DAG.gif",
    "occupy-net-evanroth-03.gif",
    "unicorn-evanroth-occupy.gif",
    "retake-public-domain_telegramsam.jpg",
    "chunli-evanroth-occupy.gif",
    "classwar-ahead_goulassoflosy.gif",
    "pow-evanroth-occupy.gif",
    "droid-evanroth-occupy.gif",
    # "LCKY-capitalism_adamharms.gif",
    "hulkster-evanroth-occupy.gif",
    "dino-evanroth-occupy.gif",
    # "unfucktheworld_seb.gif",
    "cxzy-dear-maslow-2.gif",
    "snoop-evanroth-occupy.gif",
    "bellydance-evanroth-occupy.gif",
    "txt-minimi_makemoney.gif",
    "frodo-evanroth-occupy.gif",
    "bowlers-evanroth-occupy.gif",
    "1319050295853-dumpfm-LCKY-capitalismidgi_trans.gif",
    "1319050301805-dumpfm-LCKY-gifpikaball02_trans.gif",
    "1319051214937-dumpfm-melipone-LCKYPIKAtrans.gif",
    "1319053612901-dumpfm-LCKY-VIP9.gif",
    "tired.gif",
    "hula.gif",
    "occupyinternet.gif",
    "occupyinternet2.gif",
    "OCC.gif",
    "denkmaltanzoccupy.gif",
    "greencybergothoccupy.gif",
    "lefttoeat3.gif",
    "PGkYC.gif",
    "Pp53n.gif",
    "lonelyidgi_protest.gif",
    "occupy-hula-1.gif",
    ]
  end

  def avatars
    # TODO deprecate this old [{avatar: "url"}] syntax, just use a vanilla array
    raw_avatars.map{|u| {:avatar => "#{server}/avatars/#{u}"} }
  end

  def default_sound_url
    "#{server}/crowd.mp3"
  end

  def server
    "http://#{request.host_with_port}"
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

def record_hit(host)
  new_record = redis.setnx("site/#{@host}/created_at", Time.now)
  if new_record
    debug "NEW PROTEST SITE! #{@host.inspect}"
    redis.sadd("sites", @host)
  end

  hits = redis.incr("site/#{@host}/hits")

  redis.sadd("site/#{@host}/uuids", request_uuid)
  uniques = redis.scard("site/#{@host}/uuids")

  debug "[#{Time.now.strftime('%m-%d-%Y %h:%m:%ms')}] embed.js: host=#{@host} hits=#{hits} uniques=#{uniques}"
rescue
  if dev?
    raise $!
  else
    # Ignore redis errors in prod and just drop data
    # TODO send me an email, or log an error to NewRelic
    STDERR.puts "ERROR recording hit: #{$!}"
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
      domain = request.referrer || params['url'] # TODO normalize these urls
      if domain.nil? || domain.empty?
        debug "No HTTP_REFERER or ?url param, not recording hit"
      else
        domain = "http://#{domain}" unless domain =~ /^http/
        uri = Addressable::URI.parse(domain)
        @host = uri.host
        @host = @host.gsub(/^www\./, '')

        # Hack to allow FAT's /occupy/ service as their own domains
        @host = [uri.host, uri.path].join if uri.host == 'fffff.at' && uri.path =~ /^\/occupy\//

        record_hit(@host)
      end

      # Calculate num of days this site has been protesting
      @beginning_of_protests = Time.parse('2011-10-19 08:00 -0700')
      @started_protesting_at = redis.get("site/#{@host}/created_at") rescue nil # prod no-redis failsafe
      @been_protesting_for = (@started_protesting_at && ((@started_protesting_at.to_i - @beginning_of_protests.to_i) / 1000 / 60 / 60 / 24).ceil || nil)
      debug "#{@host} @beginning_of_protests=#{@beginning_of_protests} @started_protesting_at=#{@started_protesting_at.inspect} @been_protesting_for=#{@been_protesting_for.inspect}"

      # horrible hack so we render "embed.html" view; :format => :html does not work
      content_type :html
      widget = erb :embed
      output = "document.write(#{widget.to_json});"
      content_type :js

      # No caching please, we record stats
      response['Cache-Control'] = "private, max-age=0, must-revalidate"
      etag(Digest::SHA1.hexdigest(output))
      output
    }
  end
end

get "/avatars" do
  respond_to do |format|
    format.json {
      # FIXME avatars should just be in a ruby method, not in a view that gets parsed...
      output = avatars.to_json
      output = "#{params[:callback]}(#{avatars})" unless params[:callback].nil? || params[:callback].empty?
      etag(Digest::SHA1.hexdigest(output))
      output
    }
    format.js {
      output = erb :'avatars'
      etag(Digest::SHA1.hexdigest(output))
      output
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
  @hosts = redis.smembers('sites')

  hits = redis.pipelined { @hosts.map{|host| redis.get("site/#{host}/hits") } }
  uniques = redis.pipelined { @hosts.map{|host| redis.scard("site/#{host}/uuids") } }

  @sites = @hosts.zip(hits, uniques).sort_by{|k,v,u| u.to_i }.reverse
  @sites = @sites[0..params[:limit].to_i] if params[:limit]

  # Cache every minute
  last_modified(Time.now)
  response['Cache-Control'] = "public, max-age=60"

  respond_to do |format|
    format.html { haml :stats }
    format.json { @sites.to_json }
    format.js { "document.write(#{content_type :html; haml :stats});" }
  end
end

get "/sites" do
  @sites = redis.smembers('sites')

  # Reject our special ffffff.at/occupy URLs
  @sites = @sites.reject{|host| host.gsub(/^https?\:\/\//, '') =~ /^fffff.at\/?occupy\// }
  @sites = @sites[0..params[:limit].to_i] if params[:limit]

  # TODO use sorted set for created_at dates! sheesh
  created_ats = redis.pipelined { @sites.map{|host| redis.get("site/#{host}/created_at") } }
  sorted = @sites.zip(created_ats).sort_by {|host,created_at| created_at && Time.parse(created_at) || Time.now }
  @sites = sorted.map{|a,b| a}

  respond_to do |format|
    format.html { haml :'sites' }
    format.json { params[:callback] && !params[:callback].empty? ? "#{params[:callback]}(#{@sites.to_json})" : @sites.to_json }
    format.js {
      content_type :html
      output = haml :sites, :layout => false
      content_type :js
      "document.write(#{output.to_json})"
    }
  end
end
