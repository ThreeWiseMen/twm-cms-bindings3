# CMSBindingTest.rb
# June 29, 2007
#


$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'CMSBinding'
require 'rubygems'
require 'memcache'

class TestCMSBindingTest < Test::Unit::TestCase

  def setup
    @source = CMSBinding::CMSSource.new({:site => '11N-0', :server => 'production.threewisemen.ca', :port => '80', :cache_server => '127.0.0.1'})
  end

  def teardown
  end

  def test_simple_article
    queue = @source.queue 'MemberProfiles', 'historyqueue'
    article = queue.articles.each{|article|
      puts "#{article.headline} - #{article.fields['Phone']}"
      puts "LOGO" unless article.attachments.empty?
    }
  end
end
