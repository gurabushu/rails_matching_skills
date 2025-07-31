Rails.application.routes.draw do
  devise_for :users
  
  # ユーザー機能
  resources :users, only: [:index, :show, :edit, :update]
  
  # ゲストログイン用のルート
  post '/users/guest_sign_in', to: 'users#guest_sign_in'
  
  # マッチング機能
  resources :matches, only: [:index, :create, :destroy] do
    member do
      patch :accept
      patch :reject
    end
  end
  
  # マッチリクエスト用のルート
  post '/users/:user_id/match', to: 'matches#create', as: 'create_match'
  delete '/users/:user_id/match', to: 'matches#destroy', as: 'destroy_match'
  
  # チャット機能
  resources :chat_rooms, only: [:index, :show] do
    resources :messages, only: [:create] do
      member do
        get :download_file
      end
    end
  end
  
  # 取引機能
  resources :deals do
    member do
      patch :accept
      patch :start
      patch :complete
      patch :cancel
    end
  end
  
  # マッチから取引を作成
  resources :matches, only: [] do
    resources :deals, only: [:new, :create]
  end
  
  # 統計情報
  get 'stats', to: 'stats#index', as: 'stats_index'
  post 'stats/generate', to: 'stats#generate_stats', as: 'generate_stats'
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "users#index"
end
