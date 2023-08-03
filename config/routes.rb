# frozen_string_literal: true

Rails.application.routes.draw do
  root 'alma_indexing#index'
  post 'process', to: 'alma_indexing#process_ids'
end
