helpers do

  def dev?
    Sinatra::Application.environment.to_s != 'production'
  end

  def default_avatars
    [
      '1.gif', '2.gif', '3.gif', # by @fi5e
      '4.png', '5.png', '6.png', '7.png', '8.png', '9.png', '10.png', '11.png', '12.png','13.jpg','14.png','15.png','16.png','17.png' # by @arambartholl
    ]
  end

  def set_cookie(key, value, opts={})
    # puts "Setting cookie: #{key} => #{value}"
    # TODO need to ensure setting HttpOnly
    # FIXME with headers not working?
    # domain = request.host
    # expires = Time.now + (60 * 60 * 24 * 30 * 365 * 50) # 50 years
    # response.set_cookie(key, {:value => value.to_s, :path => '/', :domain => domain, :expires => expires}.merge(opts))
    response.set_cookie(key, value)
  end

  def request_uuid
    request.cookies['uuid']
  end

  def request_avatar
    request.cookies['avatar'] = nil if request.cookies['avatar'] && request.cookies['avatar'].empty? # FIXME don't allow blanks
    request.cookies['avatar'] || '' # FIXME blank string is lame
  end

  def request_custom_avatar
    request.cookies['custom_avatar']
  end

  def request_tagline
    request.cookies['tagline']
  end

  def default_tagline
    ['Damn the man', 'Hack the planet', 'WTF'].shuffle.first
  end

  def participating?
    request.cookies['participating'].to_s == 'true'
  end

  # Object fetching filters
  def get_site(url)
    url = url.gsub(/^(.*)(\:\/\/)([A-Z0-9\-\_\.\:]+)(\/.*)$/i, '\3') rescue nil
    url = url.gsub(/^http\:\/\//,'') if url =~ /^http\:\/\//
    url = url.gsub(/^www\./,'') if url =~ /^www\./
    return make_error("Invalid site URL") if url.blank?

    site = Site.find_by_domain(url) rescue nil
    site ||= Site.create(:domain => url)
    return site
  end

  # Generalized responses
  def make_error(err=nil)
    err ||= 'Unknown Error'
    @error = err

    respond_to do |format|
      format.json { halt 500, make_json({:error => err}) }
      format.html { haml :error }
    end
  end

  def make_json(obj={})
    str = obj.to_json
    str = "#{params[:callback]}(#{str})" unless params[:callback].blank?
    return str
  end


protected

  UUID_SALT = "ourc4azyrandomSALTv3ryl0ng__9384234" # Don't change this
  def generate_uuid
    inputs = [request.ip, request.user_agent, UUID_SALT]
    Digest::SHA1.hexdigest(inputs.join('_'))
  end

  def generate_and_set_uuid
    value = generate_uuid
    set_uuid(value)
    value
  end

  def set_uuid(value)
    set_cookie("uuid", value)
  end

  def generate_and_set_avatar(value=nil)
    value ||= default_avatars.shuffle[0]
    set_avatar(value)
    value
  end

  def set_avatar(value)
    set_cookie("avatar", value)
  end


end
