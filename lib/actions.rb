put "/count" do

  return make_error("Missing UUID") if params[:uuid].blank?
  @site = get_site(params[:url])
  @visit = Visit.first(:uuid => params[:uuid], :site_id => @site.id) rescue nil
  
  if @visit.blank?
    @visit = Visit.create(:uuid => params[:uuid], :site_id => @site.id)
    @site.visits_count += 1
    @site.save
  end

  respond_to do |format|
    format.json { make_json({:site => @site.domain, :visits => @site.visits_count, :created_at => @site.created_at, :updated_at => @site.updated_at}) }
    format.html { haml :'api/site' }
  end
end


get "/site" do
  @site = get_site(params[:url])

  respond_to do |format|
    format.json { make_json({:site => @site.domain, :visits => @site.visits_count, :created_at => @site.created_at, :updated_at => @site.updated_at}) }
    format.html { haml :'api/site' }
  end
end


# ----

get "/tools/update/:browser" do
  redirect "http://addons.gleuch.com/occupyinterenet/updates/#{params[:browser]}"
end


get "/" do
  redirect "http://occupyinter.net"
end