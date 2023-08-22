# frozen_string_literal: true

Rails.application.routes.draw do
  root 'alma_indexing#index'
  post 'process', to: 'alma_indexing#process_ids'
  get 'webhook_indexing', to: 'webhook_indexing#challenge'
  post 'webhook_indexing', to: 'webhook_indexing#listen'
end
