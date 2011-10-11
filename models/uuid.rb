class UUID
  include DataMapper::Resource

  property :id,                   Serial
  property :uuid,                 String
  # property :slogan,               String
  property :created_at,           DateTime
  property :updated_at,           DateTime

end