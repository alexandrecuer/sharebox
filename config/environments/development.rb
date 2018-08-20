Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.seconds.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker
  config.action_mailer.default_url_options = { host: ENV.fetch('DOMAIN'), port: 3000 }
  
  config.action_mailer.delivery_method = :smtp
  
  config.action_mailer.smtp_settings = {
    address:                ENV.fetch('SMTP_ADDRESS'),
    port:                   ENV.fetch('SMTP_PORT'),
    domain:                 ENV.fetch('DOMAIN'),
    user_name:              ENV.fetch('GMAIL_USERNAME'),
    password:               ENV.fetch('GMAIL_PASSWORD'),
    authentication:         :plain,
    enable_starttls_auto:   true
  } 
  # error with ENV variables starting by / addition of an 21 char prefix : C:/RailsInstaller/Git'
  # we remove this prefix
  #AWS_SAK = ENV.fetch('AWS_SECRET_ACCESS_KEY')[21,ENV.fetch('AWS_SECRET_ACCESS_KEY').length-21]
  #ERRATUM : when using a .env file and node foreman, the problem disappears
  config.local_storage=1
  
  if (config.local_storage==0)
    config.paperclip_defaults = {
      storage: :s3,
      s3_credentials: {
          bucket: ENV.fetch('S3_BUCKET_NAME'),
          access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
          secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'),
          s3_region: ENV.fetch('AWS_REGION'),
          s3_host_name: ENV.fetch('AWS_HOST_NAME'),
      }
    }
  end

end
