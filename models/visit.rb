class Visit
  include DataMapper::Resource

  property :id,               Serial
  property :site_id,          Integer, :index => true
  property :user_id,          Integer, :index => true
  property :created_at,       DateTime
  property :updated_at,       DateTime

  belongs_to :site
  belongs_to :user

end
