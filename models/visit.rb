class Visit
  include DataMapper::Resource

  property :id,               Serial
  property :site_id,          Integer
  property :uuid,             String
  property :avatar,           String
  property :tagline,          String
  property :created_at,       DateTime
  property :updated_at,       DateTime

  belongs_to :site

end
