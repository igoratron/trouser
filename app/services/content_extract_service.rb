require 'net/http'
require 'uri'
require 'timeout'
require 'readability'

# ContentExtractService
#
# A service class that extracts readable content from web pages using the readability gem.
# It fetches HTML content from a given URL and extracts the main text, images, and formatting.
#
# Usage:
#   service = ContentExtractService.new("https://example.com/article")
#   result = service.call
#
# Custom options:
#   service = ContentExtractService.new(url, {
#     tags: %w[p h1 h2 h3 strong em ul ol li table],
#     attributes: %w[src href alt title],
#     preserve_images: true,
#     min_image_width: 100,
#     min_image_height: 100
#   })
#
# Returns a hash with:
#   - :url - The original URL
#   - :title - Extracted title
#   - :content - HTML content with formatting preserved
#   - :text_content - Plain text version
#   - :images - Array of image objects with src, alt, title, width, height
#   - :word_count - Number of words in the content
#   - :summary - Auto-generated summary (if content is long enough)
#   - :extracted_at - Timestamp when content was extracted
#
# Error handling:
#   - ContentExtractService::InvalidUrlError - Invalid URL format
#   - ContentExtractService::NetworkError - Network/HTTP errors
#   - ContentExtractService::ParseError - Content parsing errors
#
class ContentExtractService
  class Error < StandardError; end
  class NetworkError < Error; end
  class InvalidUrlError < Error; end
  class ParseError < Error; end

  attr_reader :url, :options

  def initialize(url, options = {})
    @url = url
    @options = default_options.merge(options)
  end

  def call
    validate_url!
    html_content = fetch_html_content
    extract_content(html_content)
  rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error, SocketError => e
    raise NetworkError, "Failed to fetch content from #{url}: #{e.message}"
  rescue URI::InvalidURIError => e
    raise InvalidUrlError, "Invalid URL: #{e.message}"
  rescue => e
    raise ParseError, "Failed to parse content: #{e.message}"
  end

  private

  def default_options
    {
      # Tags to preserve for formatting
      tags: %w[div p h1 h2 h3 h4 h5 h6 strong b em i u blockquote ul ol li table tr td th thead tbody tfoot img a br hr pre code figure],
      # Attributes to preserve
      attributes: %w[src href alt title id],
      # Remove empty nodes
      remove_empty_nodes: false,
      # Preserve images
      preserve_images: true,
      # Minimum image dimensions
      min_image_width: 100,
      min_image_height: 100,
      # Debug mode
      debug: false
    }
  end

  def validate_url!
    uri = URI.parse(url)
    raise InvalidUrlError, "URL must have http or https scheme" unless %w[http https].include?(uri.scheme)
  rescue URI::InvalidURIError => e
    raise InvalidUrlError, "Invalid URL format: #{e.message}"
  end

  def fetch_html_content(url = self.url, attempt = 1)
    Rails.logger.info "Fetching HTML content for #{url}, attempt #{attempt}"
    uri = URI.parse(url)
    
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 10, read_timeout: 30) do |http|
     request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = 'Mozilla/5.0 (compatible; ContentExtractService/1.0)'
      request['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
      
      response = http.request(request)
      
      case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPRedirection
        redirect_url = response['location']
        raise NetworkError, "Too many redirects" if redirect_url.nil? || attempt > 3
        
        redirect_url = URI.join(url, redirect_url).to_s unless redirect_url.start_with?('http')
        fetch_html_content(redirect_url, attempt + 1)
      else
        raise NetworkError, "HTTP Error: #{response.code} #{response.message}"
      end
    end
  end

  def extract_content(html_content)
    # Create readability document with options
    readability_options = {
      tags: options[:tags],
      attributes: options[:attributes],
      remove_empty_nodes: options[:remove_empty_nodes],
      debug: options[:debug]
    }
    
    if options[:min_image_width] || options[:min_image_height]
      readability_options[:min_image_width] = options[:min_image_width]
      readability_options[:min_image_height] = options[:min_image_height]
    end

    doc = Readability::Document.new(html_content, readability_options)
    # Convert relative image URLs to absolute URLs in content
    content_with_absolute_urls = convert_relative_image_urls(doc.content)

    result = {
      url: url,
      title: extract_title(doc),
      content: content_with_absolute_urls,
      text_content: extract_text_content(content_with_absolute_urls),
      images: extract_images(doc),
      word_count: count_words(content_with_absolute_urls),
      extracted_at: Time.current
    }

    # Add summary if content is long enough
    if result[:word_count] > 100
      result[:summary] = extract_summary(result[:text_content])
    end

    result
  end

  def extract_title(doc)
    # Try to get title from readability document
    title = doc.title rescue nil
    
    # If no title found, try to extract from content
    if title.blank?
      content_doc = Nokogiri::HTML::DocumentFragment.parse(doc.content)
      title_element = content_doc.at_css('h1, h2, h3')
      title = title_element&.text&.strip
    end

    title || 'Untitled'
  end

  def extract_text_content(html_content)
    doc = Nokogiri::HTML::DocumentFragment.parse(html_content)
    doc.text.strip
  end

  def extract_images(doc)
    return [] unless options[:preserve_images]

    begin
      # Use readability's image extraction if available
      images = doc.images rescue []
      
      # If readability doesn't provide images, extract from content
      if images.empty?
        content_doc = Nokogiri::HTML::DocumentFragment.parse(doc.content)
        img_elements = content_doc.css('img')
        
        images = img_elements.map do |img|
          src = img['src']
          next if src.blank?
          
          # Convert relative URLs to absolute URLs
          src = URI.join(url, src).to_s unless src.start_with?('http')
          
          {
            src: src,
            alt: img['alt'] || '',
            title: img['title'] || '',
          }
        end.compact
      else
        images = images.map do |url|
          {
            src: url,
            alt: '',
            title: ''
          }
        end
      end
      
      images
    rescue => e
      Rails.logger.warn "Failed to extract images: #{e.message}" if defined?(Rails)
      []
    end
  end

  def extract_summary(text_content, max_length = 300)
    # Simple summary extraction - take first few sentences
    sentences = text_content.split(/[.!?]+/).map(&:strip).reject(&:blank?)
    
    summary = ''
    sentences.each do |sentence|
      if (summary + sentence).length <= max_length
        summary += sentence + '. '
      else
        break
      end
    end
    
    summary.strip
  end

  def count_words(html_content)
    text = extract_text_content(html_content)
    text.split(/\s+/).length
  end

  def convert_relative_image_urls(html_content)
    return html_content if html_content.blank?

    begin
      doc = Nokogiri::HTML::DocumentFragment.parse(html_content)
      
      # Find all img tags and convert relative URLs to absolute URLs
      doc.css('img').each do |img|
        src = img['src']
        next if src.blank? || src.start_with?('http')
        
        # Convert relative URL to absolute URL
        absolute_url = URI.join(url, src).to_s
        img['src'] = absolute_url
      end
      
      doc.to_html
    rescue => e
      Rails.logger.warn "Failed to convert relative image URLs: #{e.message}" if defined?(Rails)
      html_content
    end
  end
end 