# frozen_string_literal: true

Rails.application.routes.draw do
  get 'index-by-identifier', to: 'alma_indexing#index'
  post 'process', to: 'alma_indexing#process_ids'

  get 'webhook-indexing', to: 'webhook_indexing#challenge'
  post 'webhook-indexing', to: 'webhook_indexing#listen'

  root to: redirect('/index-by-identifier')
end
