class User
  include DataMapper::Resource

  property :id,                   Serial
  property :uuid,                 String, :required => true, :index => true
  property :avatar,               String
  property :tagline,              String
  property :created_at,           DateTime
  property :updated_at,           DateTime

  has n, :visits
  # has n, :sites, :through => :visits

  def self.default_avatars
    files = Dir["#{settings.root}/public/avatars/*"]
    files.map{|f| f.gsub(/^\.\/public\/avatars\//, '') }
  end

  def self.random_avatar
    User.default_avatars.shuffle.first
  end

  # FIXME REMOVEME gross hack
  def self.broken_avatar?(avatar)
    !(avatar =~ /http/) && !File.exists?("#{settings.root}/public/avatars/#{avatar}")
  end

  def self.fix_avatar(avatar, basepath=nil)
    return nil if avatar.nil?

    # replace local 404s with random
    if broken_avatar?(avatar)
      puts "Local avatar 404! Randomizing..."
      avatar = User.random_avatar
      puts " ==> #{avatar}"
      # FIXME reset user field + cookie!
    else
      puts "Valid Avatar: #{avatar}"
    end

    avatar
  end

  def public_attributes(basepath=nil)
    allowed = [:uuid, :avatar, :tagline]
    self.avatar = User.fix_avatar(self.avatar, basepath) if basepath #REMOVEME
    self.attributes.select{|k,v| allowed.include?(k) }
  end
end
