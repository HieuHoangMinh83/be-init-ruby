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

module Blog
  class Application < Rails::Application
    config.load_defaults 6.1

    config.api_only = true

    # Thêm autoload cho thư mục app/dto
    config.autoload_paths += %W[#{config.root}/app/dto]
    config.autoload_paths += %W[#{config.root}/app/dto/user]
    config.autoload_paths += %W[#{config.root}/lib]
    # Eager load lib cho môi trường production/test (Zeitwerk)
    config.eager_load_paths << Rails.root.join("lib")

    # Thêm middleware rack-cors vào
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "*"  # Thay '*' bằng domain frontend của bạn khi deploy production
        resource "*",
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head],
          expose: ["Authorization"], # nếu bạn dùng header Authorization
          max_age: 600
      end
    end
  end
end
