class Site
  include DataMapper::Resource

  property :id,               Serial
  property :domain,           String
  property :visits_count,     Integer,        :default => 0
  property :views_count,      Integer,        :default => 0
  property :created_at,       DateTime
  property :updated_at,       DateTime

  validates_is_unique :site, :scope => :site

end