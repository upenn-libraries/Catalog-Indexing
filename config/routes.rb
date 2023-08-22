# frozen_string_literal: true

Rails.application.routes.draw do
  root 'alma_indexing#index'
  scope :indexing do
    get 'by-id', to: 'alma_indexing#index'
    post 'process', to: 'alma_indexing#process_ids'

    scope :webhook do
      get 'challenge', to: 'webhook_indexing#challenge'
      post 'listen', to: 'webhook_indexing#listen'
    end
  end
end
