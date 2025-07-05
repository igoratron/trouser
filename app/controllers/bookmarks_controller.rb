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

  private

  def bookmark_params
    params.require(:bookmark).permit(:url)
  end
end 