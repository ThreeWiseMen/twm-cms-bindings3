# CMSBindingTest.rb
# June 29, 2007
#


$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'CMSBinding'

class TestCMSBindingTest < Test::Unit::TestCase

  def setup
    @cms = CMSBinding::CMSSource.new({:site => '0'})
  end

  def teardown
  end

  def test_simple_article
    article = @cms.article 'AU0-1'
    puts article.inspect
    assert_not_nil article.contents, 'Contents should not be nil'
    assert_match "Test Article - DO NOT MODIFY OR DELETE", article.headline, 'Wrong headline'
    assert_match "Test article for Nagios monitoring", article.contents, 'Wrong contents'
  end
  
  def test_simple_category
    category = @cms.category 'AU0-0'
    assert_equal("nagios", category.name)

    article = category.articles.first
    assert_match "Test Article - DO NOT MODIFY OR DELETE", article.headline, 'Wrong headline'
    assert_nil article.contents, 'Article should be a partial'
    
    article = @cms.article article.id
    assert_match "Test Article - DO NOT MODIFY OR DELETE", article.headline, 'Wrong headline'
    assert_match "Test article for Nagios monitoring", article.contents, 'Wrong contents'
  end
  
  def test_simple_queue
    queue = @cms.queue 'nagios', 'historyqueue'
    article = queue.articles.first
    assert_match "Test Article - DO NOT MODIFY OR DELETE", article.headline, 'Wrong headline'
    assert_match "Test article for Nagios monitoring", article.contents, 'Wrong contents'
  end

  def test_with_cache
    cms = CMSBinding::CMSSource.new({:site => '0', :cache_server => '127.0.0.1'})
    queue = cms.queue 'nagios', 'historyqueue'
    article = queue.articles.first
    assert_match "Test Article - DO NOT MODIFY OR DELETE", article.headline, 'Wrong headline'
    assert_match "Test article for Nagios monitoring", article.contents, 'Wrong contents'
  end

end
