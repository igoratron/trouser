class ContentExtractionJob < ApplicationJob
  queue_as :default
  
  retry_on ContentExtractService::NetworkError, wait: :exponentially_longer, attempts: 3
  retry_on ContentExtractService::InvalidUrlError, attempts: 1
  discard_on ContentExtractService::ParseError

  def perform(bookmark_id, force_refresh: false)
    bookmark = Bookmark.find(bookmark_id)
    
    # Skip if already completed and not forcing refresh
    return if bookmark.completed? && !force_refresh
    
    # Update status to processing and broadcast
    bookmark.update!(extraction_status: :processing)
    broadcast_bookmark_update(bookmark)
    
    begin
      Rails.logger.info "Starting content extraction for bookmark #{bookmark.url_id}"
      
      service = ContentExtractService.new(bookmark.url)
      extracted_data = service.call
      
      # Store the extracted content in the JSON blob
      bookmark.update!(
        content: {
          title: extracted_data[:title],
          content: extracted_data[:content],
          word_count: extracted_data[:word_count],
          summary: extracted_data[:summary],
          images: extracted_data[:images],
          extracted_at: extracted_data[:extracted_at]
        },
        extraction_status: :completed
      )
      
      broadcast_bookmark_update(bookmark)
      Rails.logger.info "Content extraction completed for bookmark #{bookmark.url_id}"
      
    rescue ContentExtractService::Error => e
      Rails.logger.error "Content extraction failed for bookmark #{bookmark.url_id}: #{e.message}"
      
      # Store error information
      bookmark.update!(
        content: {
          error: e.message,
          extracted_at: Time.current
        },
        extraction_status: :failed
      )
      
      broadcast_bookmark_update(bookmark)
      
      # Re-raise to trigger retry logic if appropriate
      raise e
    end
  end
  
  private
  
  def broadcast_bookmark_update(bookmark)
    bookmark.broadcast_replace_to(
      "bookmarks",
      target: "bookmark_#{bookmark.id}",
      partial: "bookmarks/bookmark",
      locals: { bookmark_presenter: BookmarkPresenter.new(bookmark) }
    )
  end
end
