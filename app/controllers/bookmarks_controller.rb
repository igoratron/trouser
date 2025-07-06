class BookmarksController < ApplicationController
  def index
    bookmarks = Bookmark.all.order(created_at: :desc)
    @bookmarks = bookmarks.map { |bookmark| BookmarkPresenter.new(bookmark) }
  end

  def new
    @bookmark = Bookmark.new
  end

  def create
    @bookmark = Bookmark.new(bookmark_params)
    
    if @bookmark.save
      redirect_to bookmarks_path, notice: 'Bookmark was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    bookmark = Bookmark.find_by!(url_id: params[:url_id])
    
    # Extract and store content if not already extracted
    if bookmark.content.nil?
      begin
        service = ContentExtractService.new(bookmark.url)
        extracted_data = service.call
        
        # Store the extracted content in the JSON blob
        bookmark.content = {
          title: extracted_data[:title],
          content: extracted_data[:content],
          word_count: extracted_data[:word_count],
          summary: extracted_data[:summary],
          images: extracted_data[:images],
          extracted_at: extracted_data[:extracted_at]
        }
        
        bookmark.save!
        Rails.logger.info "Content extracted and stored for bookmark #{bookmark.url_id}"
        
      rescue ContentExtractService::Error => e
        @extraction_error = e.message
        Rails.logger.error "Content extraction failed for #{bookmark.url}: #{e.message}"
        Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}"
      end
    else
      Rails.logger.info "Using cached content for bookmark #{bookmark.url_id}"
    end
    
    @bookmark_presenter = BookmarkPresenter.new(bookmark)
  end

  def destroy
    bookmark = Bookmark.find_by!(url_id: params[:url_id])
    bookmark.destroy
    
    redirect_to bookmarks_path, notice: 'Bookmark was successfully deleted.'
  end

  private

  def bookmark_params
    params.require(:bookmark).permit(:url)
  end
end 