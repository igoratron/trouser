require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RubyRailsPostgres
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    
    # Add services directory to autoload paths
    config.autoload_paths << Rails.root.join("app", "services")
    
    # Add presenters directory to autoload paths
    config.autoload_paths << Rails.root.join("app", "presenters")
    
    # Configure Active Job to use Solid Queue
    config.active_job.queue_adapter = :solid_queue
  end
end
