# CMSBindingTest.rb
# June 29, 2007
#


$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'CMSBinding'

class TestCMSBindingTest < Test::Unit::TestCase

  def setup
    @cms = CMSBinding::CMSSource.new({:site => '12D-2T'})
  end

  def teardown
  end

  def test_simple_article
    article = @cms.article 'ALJ-9V'
    assert_not_nil article.contents, 'Contents should not be nil'
    assert_match "Nagios Test Article - DO NOT CHANGE OR DELETE", article.headline, 'Wrong headline'
    assert_match "Test article for Nagios monitoring", article.contents, 'Wrong contents'
  end
  
  def test_simple_category
    category = @cms.category 'ALJ-9U'
    assert_equal("nagios", category.name)

    article = category.articles.first
    assert_match "Nagios Test Article - DO NOT CHANGE OR DELETE", article.headline, 'Wrong headline'
    assert_nil article.contents, 'Article should be a partial'
    
    article = @cms.article article.id
    assert_match "Nagios Test Article - DO NOT CHANGE OR DELETE", article.headline, 'Wrong headline'
    assert_match "Test article for Nagios monitoring", article.contents, 'Wrong contents'
  end
  
  def test_simple_queue
    queue = @cms.queue 'nagios', 'historyqueue'
    article = queue.articles.first
    assert_match "Nagios Test Article - DO NOT CHANGE OR DELETE", article.headline, 'Wrong headline'
    assert_match "Test article for Nagios monitoring", article.contents, 'Wrong contents'
  end

  def test_with_cache
    cms = CMSBinding::CMSSource.new({:site => '12D-2T', :cache_server => '127.0.0.1'})
    queue = cms.queue 'nagios', 'historyqueue'
    article = queue.articles.first
    assert_match "Nagios Test Article - DO NOT CHANGE OR DELETE", article.headline, 'Wrong headline'
    assert_match "Test article for Nagios monitoring", article.contents, 'Wrong contents'
  end

end
