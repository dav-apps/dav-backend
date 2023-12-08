source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'
gem 'rails', '7.0.8'

# Tests
gem 'minitest-rails'

# Use Puma as the app server
gem 'puma', '~> 4.1'

# mysql for development database
gem 'mysql2'

# postgresql for production database
gem 'pg'

# redis as the data store for Sidekiq workers and Websocket connections
gem 'redis'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

# Sidekiq for asynchronous workers
gem 'sidekiq'

# Sending emails
gem 'resend', '~> 0.7.2'

# Sending notifications
gem 'web-push'

# Password encryption
gem 'bcrypt'

# Bootstrap emails
gem 'bootstrap-email', ">= 1.1.2"
gem 'sass-rails'

# AWS S3 SDK for DigitalOcean Spaces
gem 'aws-sdk-s3'

# S-Expression parser
gem 'sexpistol', git: 'https://github.com/dav-apps/sexpistol'

# Blurhash
gem 'blurhash'

# Image processing
gem 'rmagick'
gem 'mini_magick'

# Generating CUIDs (Collision-resistant ids)
gem 'cuid'

# Stripe
gem 'stripe'
gem 'stripe_event'
gem 'stripe-ruby-mock', :require => 'stripe_mock'

# Monitoring
gem "rorvswild"

# Sending HTTP requests
gem "httparty"

group :development, :test do
	gem 'dotenv-rails'
end

group :development do
  gem 'listen', '~> 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
