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
      # Trigger background content extraction
      ContentExtractionJob.perform_later(@bookmark.id)
      redirect_to bookmarks_path, notice: 'Bookmark was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    bookmark = Bookmark.find_by!(url_id: params[:url_id])
    
    # Trigger re-extraction if no_cache is requested
    if params[:no_cache].present?
      ContentExtractionJob.perform_later(bookmark.id, force_refresh: true)
      Rails.logger.info "Re-extraction job queued for bookmark #{bookmark.url_id}"
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