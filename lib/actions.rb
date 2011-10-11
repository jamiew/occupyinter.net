
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
  # FIXME i want "first_or_initialize" then only save if new?.. fuckin DM
  @user.avatar ||= request_avatar
  @user.tagline ||= request_tagline
  @user.save

  @visit = Visit.first_or_create(:user_id => @user.id, :site_id => @site.id)
  # TODO if existing record, bump its updated_at or expires_at
  @site.visits_count += 1

  @site.flush_protestors if params[:flush].to_s == 'true'
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

  basepath = ["http://", request.host_with_port].join

  output = {
    :site => site.domain,
    :visits => site.visits_count,
    :uniques => site.unique_visits_count,

    :protestors => @site.protestors(basepath).map{|u| u.public_attributes(basepath) }, # FIXME stop using basepath
    :protestor_count => @site.protestor_count,
    :protestor_avatars => @site.protestors.map{|x| User.fix_avatar(x.avatar, basepath) }, # REMOVEME completely

    :uuid => request_uuid,
    :avatar => User.fix_avatar(request_avatar, basepath), # FIXME stop using basepath
    :tagline => request_tagline,
  }

  respond_to do |format|
    format.json { make_json(output) }
    format.html { haml :'api/site' }
  end
end


# Avatar selector
get "/" do
  respond_to do |format|
    format.html { haml :avatars }
  end
end

# Set user config options: avatar, tagline, etc
# TODO make this PUT
get "/settings" do
  # puts "params => #{params.inspect}"
  @user = User.first_or_create(:uuid => request_uuid)

  @user.avatar = params[:avatar] unless params[:avatar].blank?
  set_cookie('avatar', params[:avatar])
  @user.tagline = params[:tagline] unless params[:tagline].blank?
  set_cookie('tagline', params[:tagline])
  @user.save!

  respond_to do |format|
    format.json { make_json(response.cookies['settings']) }
    format.html { redirect '/' }
  end
end

# Addon update URL
get "/tools/update/:browser" do
  redirect "http://addons.gleuch.com/occupyinterenet/updates/#{params[:browser]}"
end
