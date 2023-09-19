# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

gem 'bootsnap', require: false
gem 'bootstrap', '~> 5.2.3'
gem 'bootstrap_form', '~> 5.0'
gem 'config'
gem 'devise'
gem 'dry-transaction'
gem 'faraday'
gem 'importmap-rails'
gem 'net-sftp'
gem 'omniauth'
gem 'omniauth-rails_csrf_protection'
gem 'pennmarc', '~> 1'
gem 'pg', '~> 1.1'
gem 'puma', '~> 5.0'
gem 'rails', '~> 7.0.6'
gem 'rsolr'
gem 'rubyzip'
gem 'sassc-rails'
gem 'sidekiq', '~> 7'
gem 'sprockets-rails'
gem 'stimulus-rails'
gem 'traject'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
gem 'upennlib-rubocop', require: false

group :development, :test do
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails', '~> 6.0'
  gem 'rspec-rails', '~> 6.0.0'
  gem 'webmock'
  gem 'capybara'
  gem 'selenium-webdriver'
end

group :test do
  gem 'rspec-sidekiq'
  gem 'rspec-solr'
end

group :development do
  gem 'web-console'
end
