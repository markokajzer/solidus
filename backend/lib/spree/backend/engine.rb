# frozen_string_literal: true

require "spree/backend/config"

module Spree
  module Backend
    class Engine < ::Rails::Engine
      # Leave initializer empty for backwards-compatability. Other apps
      # might still rely on this event.
      initializer("spree.backend.environment", before: :load_config_initializers) {}

      config.after_initialize do |app|
        Spree::Backend::Config.check_load_defaults_called("Spree::Backend::Config")

        if Spree::Backend.propshaft? && app.config.respond_to?(:dartsass)
          themes = Spree::Backend::Engine.root.join("app/assets/stylesheets/spree/backend/themes")
          app.config.dartsass.builds.merge!(
            themes.glob("*.scss").to_h { |theme| [theme.to_s, Spree::Backend.dartsass_output(theme.basename(".scss").to_s)] }
          )
        end
      end
    end
  end
end
