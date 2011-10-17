class Site
  include DataMapper::Resource

  property :id,               Serial
  property :domain,           String, :required => true, :index => true
  property :visits_count,     Integer, :default => 0
  property :views_count,      Integer, :default => 0
  property :created_at,       DateTime
  property :updated_at,       DateTime

  # validates_presence_of :domain
  validates_is_unique :domain

  has n, :visits
  # has n, :users, :through => :visits

  def unique_visits_count
    # FIXME datampper can't do .count(distinct...) or .count.group_by() ?!
    Visit.count(:user_id, :conditions => {:site_id => self.id})
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

  # Turn protestors into Users
  def protestors(basepath=nil)
    return @protestors unless @protestors.nil? # memoized

    uuids = protestor_uuids
    visits = Visit.all(:site_id => self.id)
    user_ids = visits.map(&:user_id).compact.uniq
    users = User.all(:id => user_ids)

    # Strip bad elements... TODO where are these being made?!
    users.reject!{|u| u.uuid.nil? }

    @protestors = users
  end

  def protestors=(users)
    redis.del(protestors_key)
    # redis.multi
    users.each{|user| add_protestor(user) }
    # redis.exec
    users
  end

  def add_protestor(user)
    # TODO use time-based expiry and/or sorted-sets
    # so we only get protestors who were active in the last N minutes
    puts "add_protestor =========> user=#{user.inspect}"
    self.visits_count = self.visits_count + 1 # FIXME DM needs increment/decrement
    self.save!

    redis.sadd(protestors_key, user.id)
  end

  def remove_protestor(user)
    puts "#{site.domain}: removing protestor: #{visit.user.inspect}"
    self.visits_count = self.visits_count - 1 # FIXME DM needs increment/decrement
    self.save!

    redis.srem(protestors_key, user.id)
  end

  def flush_old_visits
    expiry = 30 * 24 * 60 * 60 * 60 # 30.days
    visits = Visit.all(:site_id => self.id)
    puts "Time.now=#{Time.now.to_i}"
    expired_visits = visits.select{|v| (Time.now - expiry) > Time.parse(v.updated_at.to_s) }
    puts "#{expired_visits.length} expired visits"
    expired_visits.each do |visit|
      remove_protestor(visit.user)
    end
  end

end
