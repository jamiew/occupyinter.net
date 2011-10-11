class Visit
  include DataMapper::Resource

  property :id,               Serial
  property :site_id,          Integer, :index => :site_id_and_uuid
  property :uuid,             String, :index => :site_id_and_uuid
  property :avatar,           String
  property :tagline,          String
  property :created_at,       DateTime
  property :updated_at,       DateTime

  belongs_to :site

end
