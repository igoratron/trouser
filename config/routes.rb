Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Bookmarks routes
  resources :bookmarks, only: [:index, :new, :create]

  # Defines the root path route ("/")
  root "bookmarks#index"
end
