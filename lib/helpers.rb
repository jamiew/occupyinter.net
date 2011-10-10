helpers do

  def dev?
    Sinatra::Application.environment.to_s != 'production'
  end

  def get_site(url)
    url = url.gsub(/^(.*)(\:\/\/)([A-Z0-9\-\_\.\:]+)(\/.*)$/i, '\3') rescue nil
    return make_error("Invalid site URL") if url.blank? || url.match(/\//)

    site = Site.find_by_domain(url) rescue nil
    site ||= Site.create(:domain => url)
    return site
  end

  def request_uuid
    @uuid ||= request.cookies['uuid'] || generate_and_set_uuid
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

  def set_uuid_cookie(value)
    domain = request.host
    expires = Time.now + (60 * 60 * 24 * 30 * 365 * 50) # 50 years
    response.set_cookie("uuid", {:value => value, :path => '/', :domain => domain, :expires => expires} )
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
