require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DavBackend
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.action_cable.allowed_request_origins = [
      nil,
      "http://localhost:2001",
      "http://localhost:3000",
      "http://localhost:3001",
      "http://localhost:3002",
      "http://localhost:3003",
      "http://localhost:3004",
      "https://dav-apps.tech",
		  "https://dav-website-fm4ae.ondigitalocean.app",
		  "https://dav-website-staging-o3oot.ondigitalocean.app",
      "https://calendo.dav-apps.tech",
		  "https://calendo-yp34u.ondigitalocean.app",
      "https://calendo-staging-v3c9p.ondigitalocean.app",
      "https://pocketlib.dav-apps.tech",
		  "https://pocketlib-nzgpy.ondigitalocean.app",
		  "https://pocketlib-staging-d9rk6.ondigitalocean.app",
		  "https://pocketlib.app",
      "https://storyline-staging-a6ylk.ondigitalocean.app",
      "https://storyline-e36eu.ondigitalocean.app",
      "https://storyline.press"
    ]

    Rails.application.config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins 'localhost:2001',
          'localhost:3000',
          'localhost:3001',
          'localhost:3002',
          'localhost:3003',
          'localhost:3004',
          'dav-apps.tech',
			    'dav-website-fm4ae.ondigitalocean.app',
			    'dav-website-staging-o3oot.ondigitalocean.app',
          'calendo.dav-apps.tech',
			    'calendo-yp34u.ondigitalocean.app',
          'calendo-staging-v3c9p.ondigitalocean.app',
          'pocketlib.dav-apps.tech',
			    'pocketlib-nzgpy.ondigitalocean.app',
			    'pocketlib-staging-d9rk6.ondigitalocean.app',
			    'pocketlib.app',
          'storyline-staging-a6ylk.ondigitalocean.app',
          'storyline-e36eu.ondigitalocean.app',
          'storyline.press'
        resource '*',
        headers: :any,
        methods: %i(get post put patch delete options head)
      end
    end
  end
end
