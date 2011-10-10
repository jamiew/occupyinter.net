helpers do

  def dev?
    Sinatra::Application.environment.to_s != 'production'
  end

  def get_site(url)
    url = url.gsub(/^(.*)(\:\/\/)([A-Z0-9\-\_\.\:]+)(\/.*)$/i, '\3') rescue nil
    return nil if url.blank? || url.match(/\//)

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
    output = {:site => site.domain, :visits => site.visits_count, :created_at => site.created_at, :updated_at => site.updated_at}

    respond_to do |format|
      format.json { make_json(output) }
      format.html { haml :'api/site' }
    end
  end


end
