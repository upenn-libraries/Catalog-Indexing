# frozen_string_literal: true

require 'sidekiq/pro/web'

Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  devise_scope :user do
    post 'sign_out', to: 'devise/sessions#destroy', as: 'destroy_user_session'
  end

  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

  get 'login', to: 'login#index'

  authenticated do
    root to: 'alma_exports#index', as: 'authenticated_root'
  end

  root to: redirect('/login')

  resources :users, except: :destroy

  resources :config_items, only: %w[index update]

  scope :indexing do
    get 'adhoc', to: 'alma_indexing#index', as: 'adhoc_indexing'
    post 'add', to: 'alma_indexing#add', as: 'add_by_id'
    post 'delete', to: 'alma_indexing#delete', as: 'delete_by_id'

    scope :webhook do
      get 'listen', to: 'webhook_indexing#challenge', as: 'webhook_challenge'
      post 'listen', to: 'webhook_indexing#listen', as: 'webhook_listen'
    end
  end

  resources :alma_exports, only: %i[index show destroy] do
    resources :batch_files, only: %i[index show]
  end

  # Enable Rails built in health check endpoint. This endpoint is not suitable for checking uptime because it doesn't
  # consider all of the application's services.
  get 'up', to: 'rails/health#show', as: :rails_health_check
end
