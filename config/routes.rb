Rails.application.routes.draw do
  # --------------------------------------------------------------------------------
  # api/*
  # --------------------------------------------------------------------------------
  namespace :api do
    namespace :pin do
      post :all
      post :add
      post :remove
      post :clear
    end

    # RESTful subscriptions (7 actions pattern)
    resources :subscriptions, only: %i[show create update destroy] do
      resource :rate, only: :update, controller: "subscriptions/rates"
    end
    # Bulk operations as singular resources
    resource :subscriptions_notification, only: :update,
                                          controller: "subscriptions/notifications", as: :subscriptions_notifications
    resource :subscriptions_visibility, only: :update,
                                        controller: "subscriptions/visibilities", as: :subscriptions_visibilities
    resource :subscriptions_folder, only: :update,
                                    controller: "subscriptions/folders", as: :subscriptions_folders

    namespace :feed do
      # RESTful resources
      resources :discoveries, only: :create
      resources :favicons, only: :create

      # Legacy routes (backward compatibility)
      match :discover, to: "discoveries#create", via: %i[get post]
      post :subscribe, to: "/api/subscriptions#create"
      post :unsubscribe, to: "/api/subscriptions#destroy"
      match :subscribed, to: "/api/subscriptions#show", via: %i[get post]
      post :update, to: "/api/subscriptions#update"
      post :move, to: "/api/subscriptions/folders#update"
      post :set_rate, to: "/api/subscriptions/rates#update"
      post :set_notify, to: "/api/subscriptions/notifications#update"
      post :set_public, to: "/api/subscriptions/visibilities#update"
      post :add_tags
      post :remove_tags
      post :fetch_favicon, to: "favicons#create"
    end

    namespace :folder do
      post :create
      post :delete
      post :update
    end

    namespace :config do
      match :load, action: :getter, via: %i[post get]
      post  :save, action: :setter
    end

    %w[all unread touch_all touch item_count unread_count crawl].each do |name|
      match name, via: %i[get post]
    end

    %w[subs lite_subs error_subs folders].each do |name|
      post name
    end
  end

  # other API call routes to blank page
  match 'api/*_' => 'application#nothing', via: %i[post get]

  # --------------------------------------------------------------------------------
  # other pages
  # --------------------------------------------------------------------------------
  namespace :subscribe do
    get '', action: :index, as: :index
    get '*url', action: :confirm, format: false
    post '*url', action: :subscribe, format: false, as: nil
  end

  namespace :about do
    get '*url', action: :index, format: false
  end

  namespace :user do
    get ':login_name', action: :index
  end

  namespace :favicon do
    get '*feed', action: :get
  end

  resource :members, only: :create
  get 'signup', to: 'members#new', as: :sign_up

  resource :session, only: :create
  get 'login', to: 'sessions#new', as: :login
  get 'logout', to: 'sessions#destroy', as: :logout

  root to: 'reader#welcome'

  get 'reader', to: 'reader#index'

  namespace :contents do
    get :guide
    get :config, action: :configure
    get :manage
  end

  get 'share', to: 'share#index', as: 'share'

  namespace :import do
    get '', action: :index
    post '', action: :fetch
    get '*url', action: :fetch, format: false
    post :finish
  end

  namespace :export do
    get :opml, as: ''
  end

  namespace :account do
    get '', action: :index, as: :index
    %w[apikey backup password share].each do |name|
      get name
    end
    post 'apikey'
    post 'password'
  end

  namespace :rpc do
    %w[update_feed check_digest update_feeds export].each do |name|
      match name, via: %i[post get]
    end
  end

  namespace :utility do
    namespace :bookmarklet do
      get '', action: :index
    end
  end

  get '/contents/edit', to: 'contents#edit'

  get '/mobile', to: 'mobile#index'
  get '/mobile/:feed_id', to: 'mobile#read_feed'
  get '/mobile/:feed_id/read', to: 'mobile#mark_as_read'
  post '/mobile/:feed_id/read', to: 'mobile#mark_as_read'
  get '/mobile/:item_id/pin', to: 'mobile#pin'
  post '/mobile/:item_id/pin', to: 'mobile#pin'
end
