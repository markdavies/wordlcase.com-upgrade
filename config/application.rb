require_relative "boot"

require "rails/all"

require "active_storage/engine"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module WordlacesComUpgrade
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    # config.autoload_lib(ignore: %w(assets tasks))

    config.assets.precompile += [ 'wordpuzzle.js', 'wordpuzzle.css' ]

    config.autoload_paths << Rails.root.join('lib')
    config.autoload_paths << Rails.root.join('app', 'lib')

    config.version_hosts = YAML.load_file(Rails.root.join('config', 'version_hosts.yml'))

    Rails.application.config.version_hosts[Rails.env].values.each do |host|
      config.hosts << host
    end

    config.active_job.queue_adapter = :delayed_job

    config.encoding = "utf-8"

    config.action_mailer.default_url_options = { host: 'wordlaces.com' }

    config.active_storage.variant_processor = :mini_magick
    
  end
end
