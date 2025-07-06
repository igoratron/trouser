class BookmarksController < ApplicationController
  def index
    @bookmarks = Bookmark.all.order(created_at: :desc)
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
    @bookmark = Bookmark.find_by!(url_id: params[:url_id])
    
    # Extract content using ContentExtractService
    begin
      service = ContentExtractService.new(@bookmark.url)
      @extracted_content = service.call
    rescue ContentExtractService::Error => e
      @extraction_error = e.message
      Rails.logger.error "Content extraction failed for #{@bookmark.url}: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}"
    end
  end

  private

  def bookmark_params
    params.require(:bookmark).permit(:url)
  end
end 