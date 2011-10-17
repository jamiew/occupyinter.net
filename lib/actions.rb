
# Log a visit
post "/join_protest" do
  params[:url] ||= request.referrer
  return make_error("You must specify a ?url param") if params[:url].blank?
  @site = get_site(params[:url])
  join_site(@site)

  respond_to do |format|
    format.json { respond_with_stats(@site) }
    format.html { redirect(params[:url] || '/embed.js') }
  end
end

def join_site(site)
  @user = create_user_from_cookie
  puts @user.inspect
  puts site.inspect
  @visit = Visit.first_or_create(:user_id => @user.id, :site_id => site.id)
  @visit.touch

  site.add_protestor(@user)
  set_cookie('uuid', generate_and_set_uuid)
  set_cookie('avatar', generate_and_set_avatar)
  set_cookie('custom_avatar', '')
  set_cookie('tagline', default_tagline)
end

def create_user_from_cookie
  user = User.first_or_create(:uuid => request_uuid)
  user.avatar ||= request_avatar
  user.tagline ||= request_tagline
  user.save
  user
end

# Site info
get /\/(site|stats|protest)/ do
  params[:url] ||= request.referrer
  return make_error("You must specify a ?url param") if params[:url].blank?

  @site = get_site(params[:url])
  @site.flush_old_visits
  @site.flush_protestors if dev? && params[:flush].to_s == 'true'

  # Bump current user's updated_at if protesting
  if request_uuid
    puts "Bumping visit updated_at ..."
    @user = User.find_by_uuid(request_uuid)

    @visit = @user ? Visit.first(:user_id => @user.id, :site_id => @site.id) : nil
    @visit.touch if @visit
  end

  respond_to do |format|
    format.json { respond_with_stats(@site) }
    format.html { haml :'api/site' }
  end
end

def respond_with_stats(site)
  basepath = ["http://", request.host_with_port, '/avatars'].join

  output = {
    :site => site.domain,
    :visits => site.visits_count,
    :uniques => site.unique_visits_count,
    :protestors => @site.protestors(basepath).map{|u| u.public_attributes(basepath) }, # FIXME stop using basepath
    :protestor_count => @site.protestors_count,
    :protestor_avatars => @site.protestors.map{|x| User.fix_avatar(x.avatar, basepath) }, # REMOVEME completely
  }

  if protesting?
    output[:uuid] = request_uuid
    output[:avatar] = User.fix_avatar(request_avatar, basepath) # FIXME stop using basepath
    # output[:custom_avatar] = request_custom_avatar
    output[:tagline] = request_tagline
  end

  make_json(output)
end


# Avatar selector
get "/" do
  respond_to do |format|
    format.html { haml :frontpage }
  end
end

# Set user pimpings
get "/settings" do
  @user = create_user_from_cookie

  [:avatar, :custom_avatar, :tagline].each do |field|
    next if params[field].blank?
    @user.send("#{field}=", params[field])
    set_cookie(field.to_s, params[field])
  end
  @user.save!

  respond_to do |format|
    format.html { redirect params[:redirect_to] || '/' }
    format.json { make_json(response.cookies['settings']) }
  end
end

get "/embed" do
  content_type :html # so it renders widget.html, :format => :html does not work. WTF such a hack
  widget = erb :widget
  content_type :js
  respond_to do |format|
    format.js { "document.write(#{widget.to_json})" }
  end
end

get "/customize" do
  @redirect_to = request.referrer
  @site = get_site(params[:url] || request.referrer)
  puts "@redirect_to=#{@redirect_to.inspect} @site.domain=#{@site.domain}"
  join_site(@site)
  haml :customize
end

# Addon update URL
get "/tools/update/:browser" do
  redirect "http://addons.gleuch.com/occupyinterenet/updates/#{params[:browser]}"
end
