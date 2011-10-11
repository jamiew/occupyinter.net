
# Log a visit
# FIXME not normal to respect the redirect here, TODO change yo addons
# this needs to be a GET to be javascript widget friendly
put "/count" do
  query = request.query_string.blank? ? '' : "?"+request.query_string
  redirect('/join_protest'+query)
end

get "/join_protest" do
  params[:url] ||= request.referrer
  return make_error("You must specify a ?url param") if params[:url].blank?
  @site = get_site(params[:url])

  @user = User.first_or_create(:uuid => request_uuid)
  @visit = Visit.first(:uuid => @user.uuid, :site_id => @site.id) rescue nil

  if @visit.blank?
    @visit = create_visit_from_cookie(@site)
    @site.visits_count += 1
    @site.save
  end

  @site.protestors = []
  # user = {:uuid => request_uuid, :avatar => request_avatar, :tagline => request_tagline}
  @site.add_protestor(@user)

  respond_with_stats(@site)
end

# Site info: stats, crowd
get /\/(site|stats)/ do
  params[:url] ||= request.referrer
  return make_error("You must specify a ?url param") if params[:url].blank?
  @site = get_site(params[:url])
  respond_with_stats(@site)
end

def respond_with_stats(site)
  puts "protestors=====>"
  puts @site.protestors.inspect

  puts request
  basepath = ["http://", request.host_with_port].join

  output = {
    :site => site.domain,
    :visits => site.visits_count,
    :uniques => site.unique_visits_count,
    :protestors => @site.protestors(basepath), # FIXME stop using basepath
    :protestor_count => @site.protestor_count,
    :protestor_avatars => @site.protestors.map{|x| x[:avatar] }, # REMOVEME completely

    :uuid => request_uuid,
    :avatar => Site.fix_avatar(request_avatar, basepath), # FIXME stop using basepath
    :tagline => request_tagline,
  }

  respond_to do |format|
    format.json { make_json(output) }
    format.html { haml :'api/site' }
  end
end


# Avatar selector
get "/" do
  @user = User.first_or_create(:uuid => request_uuid)
  @site = Site.find_by_domain(request.host)
  @site ||= Site.new(:domain => request.host)
  @site.save! if @site.new? # FIXME how to do find_or_create_by in DM?

  @visit = create_visit_from_cookie(@site)
  puts "new visit=#{@visit.inspect}"

  @protestors = @site.protestors
  puts "protestors=#{@protestors.inspect}"

  respond_to do |format|
    format.html { haml :avatars }
  end
end

def create_visit_from_cookie(site)
  Visit.create(:uuid => request_uuid, :avatar => request_avatar, :tagline => request_tagline, :site_id => site.id)

end

# Set user config options: avatar, tagline, etc
# TODO make this PUT
get "/settings" do
  # puts "params => #{params.inspect}"
  set_cookie('avatar', params[:avatar])
  respond_to do |format|
    format.json { make_json(response.cookies['settings']) }
    format.html { redirect '/' }
  end
end

# Addon update URL
get "/tools/update/:browser" do
  redirect "http://addons.gleuch.com/occupyinterenet/updates/#{params[:browser]}"
end
