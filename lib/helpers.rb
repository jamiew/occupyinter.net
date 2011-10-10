helpers do

  def dev?
    Sinatra::Application.environment.to_s != 'production'
  end

  def request_uuid
    @request_uuid ||= request.cookies['uuid'] || generate_and_set_uuid
  end

  def request_avatar
    @request_avatar ||= request.cookies['avatar'] || generate_and_set_avatar
  end

  def generate_uuid
    inputs = [request.ip, request.user_agent]
    Digest::SHA1.hexdigest(inputs.join('_'))
  end

  def generate_and_set_uuid
    value = generate_uuid
    set_uuid_cookie(value)
    value
  end

  def set_cookie(key, value, opts={})
    puts "Setting cookie: #{key} => #{value}"
    domain = request.host
    expires = Time.now + (60 * 60 * 24 * 30 * 365 * 50) # 50 years
    # FIXME not working?
    # response.set_cookie(key, {:value => value.to_s, :path => '/', :domain => domain, :expires => expires}.merge(opts))
    response.set_cookie(key, value)
  end

  def set_uuid_cookie(value)
    set_cookie("uuid", value, :http => true)
  end

  def generate_and_set_avatar
    value = "1" # TODO randomize based on uuid
    set_avatar_cookie(value)
    value
  end

  def set_avatar_cookie(value)
    set_cookie("avatar", value, :http => true)
  end


  def get_site(url)
    url = url.gsub(/^(.*)(\:\/\/)([A-Z0-9\-\_\.\:]+)(\/.*)$/i, '\3') rescue nil
    url = url.gsub(/^http\:\/\//,'') if url =~ /^http\:\/\//
    url = url.gsub(/^www\./,'') if url =~ /^www\./
    return make_error("Invalid site URL") if url.blank?

    site = Site.find_by_domain(url) rescue nil
    site ||= Site.create(:domain => url)
    return site
  end


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

  def respond_with_stats(site)
    output = {
      :uuid => request_uuid,
      :avatar => request_avatar,
      :site => site.domain,
      :visits => site.visits_count,
      :uniques => site.unique_visits_count,
      :created_at => site.created_at,
      :updated_at => site.updated_at
    }

    respond_to do |format|
      format.json { make_json(output) }
      format.html { haml :'api/site' }
    end
  end

end
