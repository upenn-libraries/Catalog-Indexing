# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  devise_scope :user do
    post 'sign_out', to: 'devise/sessions#destroy', as: 'destroy_user_session'
  end

  get 'login', to: 'login#index'

  authenticated do
    root to: 'alma_indexing#index', as: 'authenticated_root'
  end

  root to: redirect('/login')

  resources :users, except: %w[new create edit update destroy]

  scope :indexing do
    get 'by-id', to: 'alma_indexing#index', as: 'index_by_id'
    post 'process', to: 'alma_indexing#process_ids', as: 'process_ids'

    scope :webhook do
      get 'challenge', to: 'webhook_indexing#challenge', as: 'webhook_challenge'
      post 'listen', to: 'webhook_indexing#listen', as: 'webhook_listen'
    end
  end
  resources :alma_exports, only: %i[index show destroy]
end
