require 'rubygems'
require 'memcache'

memcache = MemCache.new('127.0.0.1')
test = memcache.set("test", "data", 3600)
data = memcache.get("test")
puts data
