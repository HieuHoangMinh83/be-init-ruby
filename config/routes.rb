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
    resources :user_setting, only: [:update]
    resources :auth, only: [] do
      collection do
        get :confirm_email
        post :confirm_email

        post :login
        post :register
        get :info
      end
      member do
        post :activate
      end
    end
    resources :projects
  end
end
