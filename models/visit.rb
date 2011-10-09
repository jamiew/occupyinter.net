class Visit
  include DataMapper::Resource

  property :id,               Serial
  property :uuid,             String
  property :site_id,          Integer
  property :created_at,       DateTime

end