# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application'
pin '@popperjs/core', to: 'https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8/dist/umd/popper.min.js'
pin 'bootstrap', to: "https://cdn.jsdelivr.net/npm/bootstrap@#{Settings.bootstrap_version}/dist/js/bootstrap.bundle.min.js"
