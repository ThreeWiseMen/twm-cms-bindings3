# CMSBinding.rb

require 'net/http'
require 'rexml/document'
require 'rexml/xpath'
require 'rubygems'
require 'memcache'

module CMSBinding
  
  class Base
    def get_text( element )
      return '' unless element.kind_of? REXML::Element
      return_text = ''
      
      if( element.has_elements? )
      	formatter = REXML::Formatters::Default.new(false)
        REXML::XPath.each( element, "*") {|subElement|
          tmp = ''
          formatter.write(subElement, tmp)
          return_text += tmp
        }  
      elsif ( element.has_text? ) 
        element.texts.each {|text| 
          return_text += text.value
        }
      end
      
      return_text
    end
  end
  
  class Category < Base
    attr_reader :parent, :id, :name, :description, :category_weblink,
                :article_weblink, :cdn_image_url, :cdn_thumbnail_url,
                :sub_categories, :articles
    
    def initialize (topCategory, source, partial)
      @source = source;
      @articles = []
      @sub_categories = []
      @partial = partial
      
      @id = topCategory.attributes['id'].to_str
      @name = get_text( REXML::XPath.first( topCategory, "name" ) )
      @description = get_text( REXML::XPath.first( topCategory, "description" ) )
      @category_weblink = get_text( REXML::XPath.first( topCategory, "category_weblink" ) )
      @article_weblink = get_text( REXML::XPath.first( topCategory, "article_weblink" ) )
      
      if ( partial == false)
        @cdn_image_url = get_text( REXML::XPath.first( topCategory, "cdn_image_url" ) )
      
        @cdn_thumbnail_url = get_text( REXML::XPath.first( topCategory, "cdn_thumbnail_url" ) )
        REXML::XPath.each( topCategory, "subcategories/category") {|subCategory|
          @sub_categories << CMSBinding::Category.new( subCategory, source, true )
        }
        
        REXML::XPath.each( topCategory, "articles/article" ) {|article|
          @articles << CMSBinding::Article.new( article, source, true )
        }
      end
    end
  end
  
  class Queue
    attr_reader :queue_name, :queue_type, :articles
    
    def initialize (queue_dom, source, queue_name, queue_type)
      @source = source
      @queue_name = queue_name
      @queue_type = queue_type
      @articles = []

      REXML::XPath.each(queue_dom, "article") { |article|
        @articles << CMSBinding::Article.new( article, source, false )
      }
    end
  end
  
  class Article < Base
    attr_reader :categoryID, :id, :headline, :small_intro, :large_intro, :date,
                :contents, :keywords, :attachments, :fields
    
    def initialize (article, source, partial)
      @source = source
      @attachments = []
      @fields = {}
      @partial = partial
      
      @id = article.attributes['id'].to_str
      @headline = get_text( REXML::XPath.first( article, "headline" ) )

      if( partial == false ) 
        @categoryID = REXML::XPath.first( article, "category" ).attributes['id'].to_str
        @small_intro = get_text( REXML::XPath.first( article, "smallintro" ) )
        @large_intro = get_text( REXML::XPath.first( article, "largeintro" ) )
        @contents = get_text( REXML::XPath.first( article, "body" ) )
        @keywords = get_text( REXML::XPath.first( article, "keywords" ) ).split(',')
        @date = get_text( REXML::XPath.first( article, "date" ) )
        
        REXML::XPath.each( article, "field") {|field|
          key = field.attributes['name'].to_s
          value = get_text( REXML::XPath.first( field, "."))
          @fields[key.strip] = value.strip
        }
        REXML::XPath.each( article, "attachments/attachment" ) {|attachment|
          @attachments << CMSBinding::ArticleAttachment.new(attachment, @source)
        }
      end
    end
  end
  
  class ArticleAttachment
    attr_reader :id, :mime_type, :filename
    
    def initialize(attachment_dom, source)
      @source = source
      
      @id = attachment_dom.attributes['id'].to_str
      @mime_type = attachment_dom.attributes['mimetype'].to_str
      @filename = attachment_dom.attributes['filename'].to_str
    end
  end
  
  class CMSSource
    CMS_AP = "/cms";
    
    def initialize(config)
      if config[:site].nil?
        raise ArgumentError, ":site required"
      else
        @site = config[:site]
      end

      @server = config[:server] || 'cms.hostingoperationscentre.com'
      @port = config[:port] || '80'

      if config[:cache].nil?
        @cache_server = config[:cache_server] || nil
        unless @cache_server.nil?
          @mcache = MemCache.new(@cache_server)
          @cache_timeout = config[:cache_timeout] || 3600
        end
      else
        @mcache = config[:cache]
        @cache_timeout = config[:cache_timeout] || 3600
      end
    end
    
    def category(id)
      xml = get_response( "#{base_url}xml/category/id/#{id}" )
      document = REXML::Document.new(xml);
      category = REXML::XPath.first( document, '/category' )
      CMSBinding::Category.new(category, self, false)
    end
    
    def article(id)
      xml = get_response( "#{base_url}xml/article/id/#{id}/full" )
      document = REXML::Document.new(xml)
      first_article = REXML::XPath.first( document, "articles/article")
      CMSBinding::Article.new(first_article, self, false)
    end

    def queue(queue_name, queue_type)
      xml = get_response( "#{base_url}xml/article/#{queue_type}/#{queue_name}/all/full")
      document = REXML::Document.new(xml)
      articles = REXML::XPath.first( document, "articles")
      CMSBinding::Queue.new(articles, self, queue_name, queue_type)
    end

    def article_attachment_link(attachment)
      if attachment.kind_of? CMSBinding::ArticleAttachment
        attachment_id = attachment.id
      else
        attachment_id = attachment.to_str
      end
      
      "#{base_url}binary/article/attachment/#{attachment_id}/normal"
    end
    
    private 
    
    def base_url
      "http://#{@server}:#{@port}#{CMS_AP}/content/#{@site}/"
    end
    
    def get_response(strURL)
      content = @mcache[strURL] unless @cache.nil?
      if content.nil?
        url = URI.parse(strURL)
        req = Net::HTTP::Get.new(url.path)
        content = Net::HTTP.start(url.host, url.port) {|http|
          res = http.request(req)
          if(! res.instance_of?(Net::HTTPOK) )
            raise "Error communicating with CMS Instance '#{res.message}'"
          else
            res.body
          end
        }
        unless @cache.nil?
          @mcache.set(strURL, content, @cache_timeout)
        end
      end
      content
    end
  end
end
