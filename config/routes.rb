Rails.application.routes.draw do
  namespace :v1 do
    resources :users do
      member do
        get "details"
        post "activate"
      end
      collection do
        get "recent"
        get "search"
      end
    end

    resources :auth, only: [] do
      collection do
        post :login
        post :register
      end
      member do
        post :activate
      end
    end
  end
end
