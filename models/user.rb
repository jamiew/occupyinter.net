class User
  include DataMapper::Resource

  property :id,                   Serial
  property :uuid,                 String, :index => true
  property :avatar,               String
  property :tagline,              String
  property :created_at,           DateTime
  property :updated_at,           DateTime

  has n, :visits
  # has n, :sites, :through => :visits

  # FIXME REMOVEME gross hack
  def self.fix_avatar(avatar, basepath=nil)
    avatar = (avatar =~ /\.(png|gif|jpg)$/ ? avatar : avatar+(avatar.to_i > 3 ? '.png' : '.gif'))
    avatar.to_i > 0 ? "#{basepath}/avatars/#{avatar}" : avatar
  end

  def avatar_url
    # TODO fix this
    avatar
  end

  def public_attributes(basepath=nil)
    allowed = [:uuid, :avatar, :tagline]
    self.avatar = User.fix_avatar(self.avatar, basepath) if basepath #REMOVEME
    self.attributes.select{|k,v| allowed.include?(k) }
  end
end
