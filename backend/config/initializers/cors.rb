# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:3000', 'http://127.0.0.1:3000', 'http://frontend:3000',
            /https?:\/\/.*\.nip\.io(:\d+)?\z/,
            /https?:\/\/.*retebio\.it(:\d+)?\z/,
            *(ENV['CORS_ALLOWED_ORIGINS']&.split(',') || [])
    resource '/api/v2/*',
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options, :head],
             credentials: true
    resource '/spree_oauth/*',
             headers: :any,
             methods: [:post, :options],
             credentials: true
    resource '/rails/active_storage/*',
             headers: :any,
             methods: [:get, :options, :head]
  end
end
