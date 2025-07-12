class BookmarkPresenter
  attr_reader :bookmark

  def initialize(bookmark)
    @bookmark = bookmark
  end

  def has_images?
    content&.dig('images')&.any?
  end

  def first_image
    return nil unless has_images?
    content['images'].first
  end

  def has_title?
    content&.dig('title').present?
  end

  def title
    content&.dig('title')
  end

  def display_title
    has_title? ? title : nil
  end

  def url
    bookmark.url
  end

  def url_id
    bookmark.url_id
  end

  def word_count
    content&.dig('word_count') || 0
  end

  def has_word_count?
    word_count.present?
  end

  def display_word_count
    return nil unless has_word_count?
    "#{word_count} words"
  end

  def display_url_with_title?
    has_title?
  end

  def display_url_only?
    !has_title?
  end

  # Show page specific methods
  def content_text
    content&.dig('content')
  end

  def summary
    content&.dig('summary')
  end

  def has_summary?
    summary.present?
  end

  def images
    content&.dig('images') || []
  end

  def images_count
    images.size || 0
  end

  def has_multiple_images?
    images_count > 1
  end

  def extracted_at
    content&.dig('extracted_at')
  end

  def has_content?
    content.present?
  end
  
  # Extraction status methods
  def extraction_status
    bookmark.extraction_status
  end
  
  def pending?
    bookmark.pending?
  end
  
  def processing?
    bookmark.processing?
  end
  
  def completed?
    bookmark.completed?
  end
  
  def failed?
    bookmark.failed?
  end
  
  def extraction_error
    content&.dig('error') if failed?
  end

  private

  def content
    bookmark.content
  end
end 