# PUT /count.json?url=...
put "/count" do

  @site = get_site(params[:url])
  @visit = Visit.first(:uuid => request_uuid, :site_id => @site.id) rescue nil

  if @visit.blank?
    @visit = Visit.create(:uuid => params[:uuid], :site_id => @site.id)
    @site.visits_count += 1
    @site.save
  end

  respond_with_stats(@site)
end

# GET /site.json?url=...
get "/site" do
  return make_error("You must specify a ?url param") if params[:url].blank?
  @site = get_site(params[:url])
  respond_with_stats(@site)
end


# Addon update URL
get "/tools/update/:browser" do
  redirect "http://addons.gleuch.com/occupyinterenet/updates/#{params[:browser]}"
end

get "/" do
  redirect "http://occupyinter.net"
end