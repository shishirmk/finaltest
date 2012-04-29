# wrapper around a Redis database connection, that we
#  can use as a singleton object application wide
module RedisMod
  #  a real world application would hand over
  #  a lot of parameters to Redis.new
  @@redis_connection = REDIS
  def self.conn
    @@redis_connection
  end
end
