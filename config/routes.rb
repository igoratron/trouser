Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Bookmarks routes
  resources :bookmarks, only: [:index, :new, :create]
  
  # Custom route for showing bookmark by url_id
  get 'bookmarks/:url_id', to: 'bookmarks#show', as: 'bookmark_show'
  
  # Custom route for deleting bookmark by url_id
  delete 'bookmarks/:url_id', to: 'bookmarks#destroy', as: 'bookmark_destroy'

  # Defines the root path route ("/")
  root "bookmarks#index"
end
