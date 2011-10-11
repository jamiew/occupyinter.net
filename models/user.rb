class User
  include DataMapper::Resource

  property :id,                   Serial
  property :uuid,                 String
  property :avatar,               String
  property :tagline,              String
  property :created_at,           DateTime
  property :updated_at,           DateTime

end
