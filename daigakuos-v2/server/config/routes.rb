Rails.application.routes.draw do
  # Phase 39: Party Synergy
  post 'parties/create', to: 'parties#create'
  post 'parties/join', to: 'parties#join'
  post 'parties/leave', to: 'parties#leave'
  get 'parties/show', to: 'parties#show'
  get 'parties/status'
  root 'web/dashboard#index'

  namespace :web do
    get 'dashboard', to: 'dashboard#index'
  end

  namespace :api do
    namespace :v1 do
      get 'expeditions/start_quest'
      get 'expeditions/abandon_quest'
      get 'alchemy/craft_upgrade'
      resources :rankings, only: [:index]
      resources :analytics, only: [:index] do
        collection do
          get :heatmap
        end
      end

      resources :skills, only: [] do
        collection do
          post :use
          post :sharpen
          get :status
        end
      end

      resources :quests, only: [:index] do
        member do
          post :start
        end
      end

      resources :blacksmith, only: [:index] do
        collection do
          post :craft
        end
      end
      resources :mokos, only: [:index]
      get 'raid/status'
      get 'world/status'
      post 'sync/push'
      get  'sync/pull'
      get  'sync/insights'
    end
  end

  # Admin Web UI Portal
  namespace :admin do
    root to: "moko_templates#index"
    resources :moko_templates
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
