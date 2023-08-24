# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect('/indexing/by-id')
  scope :indexing do
    get 'by-id', to: 'alma_indexing#index', as: 'index_by_id'
    post 'process', to: 'alma_indexing#process_ids', as: 'process_ids'

    scope :webhook do
      get 'challenge', to: 'webhook_indexing#challenge', as: 'webhook_challenge'
      post 'listen', to: 'webhook_indexing#listen', as: 'webhook_listen'
    end
  end
end
