class Site
  include DataMapper::Resource

  property :id,               Serial
  property :domain,           String
  property :visits_count,     Integer,        :default => 0
  property :views_count,      Integer,        :default => 0
  property :created_at,       DateTime
  property :updated_at,       DateTime

  validates_is_unique :site, :scope => :site

  def unique_visits_count
    # FIXME datampper can't do .count(distinct...) or .count.group_by() ?!
    Visit.count(:uuid, :conditions => {:site_id => self.id})
  end


end