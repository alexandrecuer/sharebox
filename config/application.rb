require_relative 'boot'

require 'rails/all'
require 'csv'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Sharebox
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1
    config.active_job.queue_name_prefix = Rails.env
    config.time_zone = 'Paris'
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.i18n.default_locale = :fr
    
    config.action_mailer.asset_host = "http://"+ENV.fetch('DOMAIN')
    
    #a good option with a classic sharebox.yml file using section default: production, development, test
    #config.sharebox = Rails.application.config_for(:sharebox)
    
    config_path="#{Rails.root}/config/config.yml"
    config.sharebox = YAML.load_file(config_path)["conf"]
    
    # for modules auto integration
    #config.autoload_paths += Dir["#{Rails.root}/lib/**/"]
    config.eager_load_paths << "#{Rails.root}/lib"
  end
end
