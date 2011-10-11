class Site
  include DataMapper::Resource

  property :id,               Serial
  property :domain,           String,   :index => true
  property :visits_count,     Integer,  :default => 0
  property :views_count,      Integer,  :default => 0
  property :created_at,       DateTime
  property :updated_at,       DateTime

  validates_is_unique :domain

  has n, :visits

  # FIXME REMOVEME gross hack
  def self.fix_avatar(avatar, basepath=nil)
    avatar.to_i > 0 ? "#{basepath}/avatars/#{avatar}.gif" : avatar
  end

  def unique_visits_count
    # FIXME datampper can't do .count(distinct...) or .count.group_by() ?!
    Visit.count(:uuid, :conditions => {:site_id => self.id})
  end

  def protestors_key
    "/sites/#{self.id}/protestors"
  end

  def flush_protestors
    redis.del(protestors_key)
  end

  def protestor_count
    redis.scard(protestors_key)
  end

  def protestor_uuids
    redis.smembers(protestors_key)
  end

  # Turn protestors into Users (Visits)
  # TODO refactor this into actual User objects. probably
  def protestors(basepath=nil)
    uuids = protestor_uuids
    visits = uuids.map{|uuid| Visit.first(:site_id => self.id, :uuid => uuid) }.compact
    visits.map{|v| {:uuid => v.uuid, :avatar => Site.fix_avatar(v.avatar, basepath), :tagline => v.tagline} }
  end

  def protestors=(uuids)
    redis.del(protestors_key)
    # redis.multi
    uuids.each{|uuid| add_protestor(uuid) }
    # redis.exec
    uuids
  end

  def add_protestor(user)
    # TODO use time-based expiry and/or sorted-sets
    # so we only get protestors who were active in the last N minutes
    puts "add_protestor =========> user.uuid=#{user.uuid.inspect}"
    redis.sadd(protestors_key, user.uuid)
  end

end
