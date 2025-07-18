Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
  
  # Authentication routes
  namespace :auth do
    get "login" => "sessions#new", as: :login
    post "login" => "sessions#create"
    delete "logout" => "sessions#destroy", as: :logout
    
    get "signup" => "registrations#new", as: :signup
    post "signup" => "registrations#create"
  end
  
  # Convenience routes
  get "login" => "auth/sessions#new"
  get "signup" => "auth/registrations#new"
  
  # API routes
  namespace :api do
    namespace :v1 do
      resources :files, only: [:create, :show, :index, :destroy] do
        member do
          post :analyze
          get :download
          get :analysis_status
          post :cancel
        end
      end
      
      resources :analyses, only: [:show, :index]
      
      resources :payments, only: [:create, :index, :show] do
        collection do
          post :confirm
          post :webhook
        end
      end
      
      namespace :ai do
        post :chat
        post :feedback
      end
      
      resources :knowledge_threads, only: [:index, :show] do
        collection do
          get :export
          get :stats
        end
      end
      
      # Dashboard UI Integration routes
      resources :dashboard, only: [] do
        collection do
          get :status
          post 'run-pipeline' => :start_pipeline
          post 'stop-pipeline' => :stop_pipeline
          post 'run-continuous' => :start_continuous_collection
          get :logs
          get :datasets
          post 'cache/cleanup' => :cleanup_cache
          post 'collection/save' => :save_collection
        end
      end
      
      # AI Cost Monitoring routes
      resources :ai_cost_monitoring, only: [] do
        collection do
          get :balance
          get :usage
          get :models
        end
      end
      
      # Settings routes
      resources :settings, only: [] do
        collection do
          get :model
          post :model, action: :update_model
          get :openrouter, action: :openrouter_config
          post :openrouter, action: :update_openrouter_config
        end
      end
    end
  end
  
  # Admin routes
  namespace :admin do
    root "dashboard#index"
    resources :users
    resources :analyses, only: [:index, :show]
    resources :stats, only: [:index]
    
    resources :ai_cache, only: [:index, :show] do
      collection do
        post :clear_expired
        post :clear_all
      end
    end
    
    # Data Pipeline routes
    resources :data_pipeline, only: [:index] do
      collection do
        post :start_collection
        post :stop_collection
        post :restart_failed
        get :health_check
      end
      member do
        get :source_status
      end
    end
    
    # AI Cost Monitoring routes
    resources :ai_cost_monitoring, only: [:index] do
      collection do
        get :api_usage
        get :model_comparison
        get :cost_breakdown
      end
    end
    
    # Knowledge base management
    namespace :knowledge_base do
      root "dashboard#index"
      
      resources :datasets, only: [:index, :create, :show, :destroy] do
        member do
          post :process
        end
      end
      
      resources :learning, only: [:index] do
        collection do
          get :metrics
          post :start_training
          post :stop_training
        end
      end
      
      # Reddit data management
      resources :reddit, only: [:index] do
        collection do
          post :sync_data
          get :thread_analysis
          post :bulk_import
        end
      end
      
      # RAG system management
      namespace :rag do
        root "dashboard#index"
        get "stats", to: "dashboard#stats"
        get "metrics", to: "dashboard#metrics"
        get "indices", to: "dashboard#indices"
        post "indices/:index_id/optimize", to: "indices#optimize", as: :optimize_index
        get "embedding_jobs", to: "embedding_jobs#index"
        post "embedding_jobs", to: "embedding_jobs#create"
        post "test_search", to: "dashboard#test_search"
      end
    end
  end
  
  # Feature routes
  resources :excel_files do
    member do
      post :analyze
      get :download_corrected
    end
  end
  
  resources :chat_conversations do
    member do
      post :send_message
    end
  end
  
  resources :subscriptions, only: [:index, :new, :create] do
    member do
      post :cancel
    end
  end
  
  # Analytics route
  get "analytics" => "analytics#index"
  
  # Profile and Settings routes
  get "profile" => "users#profile"
  get "settings" => "users#settings"
  resources :api_keys, except: [:show]
  
  # WebSocket (using Solid Cable)
  # mount ActionCable.server => "/cable"
end
