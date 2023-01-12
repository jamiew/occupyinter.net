require 'rubygems'
require 'bundler'
Bundler.require

require 'digest/sha1'
require 'logger'
require 'json'

configure do |config|
  Sinatra::Application.register Sinatra::RespondTo

  set :sessions, true
  set :cache, Dalli::Client.new
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

  def raw_avatars
    [
      # Disabled cuz they don't have transparent bg's:
      # "Hombre-65_gyna.gif",
      # "LCKY-capitalism_adamharms.gif",
      # "unfucktheworld_seb.gif",

      "banana-evanroth-occupy.gif",
      "jig-evanroth-occupy.gif",
      "gdance-evanroth-occupy.gif",
      "david_goliath-evanroth-stevelambert-occupy.gif",
      "bugs_troll_mrqmarx.gif",
      "hallo-surfer_dragan.gif",
      "jesus-evanroth-occupy.gif",
      "moonwalk-evanroth-occupy.gif",
      "jeanluc-evanroth-occupy.gif",
      "occupy-net-evanroth-02.gif",
      "headless-evanroth-occupy.gif",
      "occupy-net-evanroth-03.gif",
      "unicorn-evanroth-occupy.gif",
      "retake-public-domain_telegramsam.jpg",
      "chunli-evanroth-occupy.gif",
      "classwar-ahead_goulassoflosy.gif",
      "pow-evanroth-occupy.gif",
      "droid-evanroth-occupy.gif",
      "hulkster-evanroth-occupy.gif",
      "dino-evanroth-occupy.gif",
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
      "weare99percent_DAG.gif",
      "oohla-occupy.gif",
      "jomon_occupy.gif",
      "ponathan-partylike99percent.gif",
      "enough-is-enough.gif",
      "telegram-sam.gif",
      "nyan_cat.gif",
      "systaime.gif",
    ]
  end

  def exhibition_avatars
    [
      'constant-dullaart-occupy.gif',
      'olia-dragan-2-occupy.gif',
      'charlie-todd-occupy.gif',
      'UBERMORGEN-occupy.gif',
      'brad-downey-occupy.gif',
      'la-quadrature-occupy-internet.gif',
      'mark-jenkins-occupy.gif',
      'olia-dragan-occupy.gif',
      'peretti-occupy-1.gif',
      'ryder-ripps-occupy.gif',
      'peretti-occupy-2.gif',
      'aram-bartholl-occupy.gif',
      'telecomix-occupy.gif',
      'rafael-rozendaal-occupy.gif',
      'moot-occupy.gif',
    ]
  end

  def avatars
    output = raw_avatars.map{|u| {:avatar => "#{server}/avatars/#{u}"} }
    output += exhibition_avatars.map{|u| {:avatar => "#{server}/exhibition/#{u}"} }
    output
  end

  def default_sound_url
    "#{server}/crowd.mp3"
  end

  def server
    "https://#{request.host_with_port}"
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

  # Incremenet raw hits counter
  hits = redis.incr("site/#{@host}/hits")

  # Fetch/set a memcache key representing this unique user,
  # for non-cookie but stillcheap uniqueness checking
  uniquecheck_key = "#{host}_#{request_uuid}"
  debug "checking unique key: #{uniquecheck_key}"
  uniquecheck = settings.cache.get(uniquecheck_key)
  if uniquecheck.nil?
    debug "Setting uniquecheck field, key=#{uniquecheck_key}"
    uniquecheck_expiry = 60 * 60 # sixty minutes till you count as a unique again
    settings.cache.set(uniquecheck_key, '1', uniquecheck_expiry)
  else
    debug "this is not a unique"
  end

  # Update our uniques count
  # Fetch the old set value and set from there if necessary
  uniques_key = "site/#{host}/uniques"
  old_uniques = redis.scard("site/#{host}/uuids")
  cookie_key = "occupyinternet_#{host}"
  uniques = if request.cookies[cookie_key].to_s == 'true' || uniquecheck == '1'
    redis.get(uniques_key)
  else
    response.set_cookie(cookie_key, true)
    redis.incr(uniques_key)
  end

  if old_uniques && uniques && (old_uniques.to_i > uniques.to_i)
    debug "uniques=#{uniques} and old_uniques=#{old_uniques}! updating value..."
    redis.set(uniques_key, old_uniques)
  end

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
  domain = request.referrer || params['url'] # TODO normalize these urls
  if domain.nil? || domain.empty?
    debug "No HTTP_REFERER or ?url param, not recording hit"
  else
    domain = "https://#{domain}" unless domain =~ /^http/
    uri = Addressable::URI.parse(domain)
    @host = uri.host
    @host = @host.gsub(/^www\./, '')

    # Hack to allow FAT's /occupy/ service as their own domains
    @host = [uri.host, uri.path].join if uri.host == 'fffff.at' && uri.path =~ /^\/occupy\//

    record_hit(@host)
  end

  # Calculate num of days this site has been protesting
  # TODO offset all dates by diff b/w beginning of protests and when we started storing dates
  @beginning_of_protests = Time.parse('2011-10-19 08:00 -0700')

  created_at = redis.get("site/#{@host}/created_at") rescue nil # prod no-redis failsafe
  @started_protesting_at = created_at && Time.parse(created_at)
  @been_protesting_for = (@started_protesting_at && ((Time.now.to_i - @started_protesting_at.to_i) / 60.0 / 60.0 / 24.0).ceil || nil)
  debug "#{@host} @beginning_of_protests=#{@beginning_of_protests} @started_protesting_at=#{@started_protesting_at.inspect} @been_protesting_for=#{@been_protesting_for.inspect}"

  respond_to do |format|
    format.js {
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
    format.html {
      erb :embed
    }
    format.json {
      content_type :html
      widget = erb :embed
      output = {:html => widget, :avatars => avatars}.to_json
      output = "#{params[:callback]}(#{output})" unless params[:callback].nil? || params[:callback].empty?
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
  uniques = redis.pipelined { @hosts.map{|host| redis.get("site/#{host}/uniques") } }

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
