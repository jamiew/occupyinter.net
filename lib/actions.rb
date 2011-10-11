
# Log a visit
put "/count" do
  @site = get_site(params[:url])
  request_uuid

  @uuid = UUID.first_or_create(:uuid => @request_uuid)
  
  # VISIT.FIRST_OR_CREATE() WOULD BE GOOD, BUT IF NOT CREATED, WE SHOuLD INCREMENT SITE'S VISITS COUNT!
  @visit = Visit.first(:uuid => @uuid.uuid, :site_id => @site.id) rescue nil

  if @visit.blank?
    @visit = Visit.create(:uuid => params[:uuid], :site_id => @site.id)
    @site.visits_count += 1
    @site.save
  end

  respond_with_stats(@site)
end

# Site stats
get "/site" do
  return make_error("You must specify a ?url param") if params[:url].blank?
  @site = get_site(params[:url])
  respond_with_stats(@site)
end

# Avatar selector
get "/" do
  puts "my uuid: #{@request_uuid}"
  request_uuid
  puts "my uuid2: #{@request_uuid}"
  @uuid = UUID.first_or_create(:uuid => @request_uuid)
  puts @uuid.inspect

  # puts request.cookies.inspect
  respond_to do |format|
    format.html { haml :avatars }
  end
end

# Set avatar
# TODO make this POST/PUT
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
