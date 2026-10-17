# frozen_string_literal: true

require "spree_core"
require "spree_api"

require "jquery-rails"
require "sassc-rails" unless defined?(Propshaft)
require "handlebars_assets"
require "font-awesome-rails"
require "jbuilder"
require "kaminari"
require "responders"

module Spree
  module Backend
    def self.propshaft?
      defined?(::Propshaft::Assembly) && Rails.application.assets.is_a?(::Propshaft::Assembly)
    end

    def self.dartsass_output(theme)
      "solidus_backend_#{theme}.css"
    end
  end
end

require "spree/backend/action_callbacks"
require "spree/backend/callbacks"
require "spree/backend/engine"
require "spree/backend/propshaft_manifest"
