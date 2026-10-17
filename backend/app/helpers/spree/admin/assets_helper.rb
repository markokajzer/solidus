# frozen_string_literal: true

module Spree
  module Admin
    module AssetsHelper
      CUSTOMIZATIONS = "spree/backend/all"

      def admin_theme_stylesheet_link_tag(theme, **options)
        path = Spree::Backend::Config.theme_path(theme)
        options = {data: {turbolinks_track: "reload"}, **options}

        return stylesheet_link_tag(path, **options) unless Spree::Backend.propshaft?

        if path == CUSTOMIZATIONS
          entries = admin_propshaft_manifest.expand(CUSTOMIZATIONS, "css") if admin_asset_exists?("#{CUSTOMIZATIONS}.css")
          stylesheet_link_tag(*(entries&.map(&:logical_path) || [Spree::Backend.dartsass_output("classic")]), **options)
        else
          stylesheet_link_tag(Spree::Backend.dartsass_output(File.basename(path)), **options)
        end
      end

      def admin_javascript_include_tag
        return javascript_include_tag(CUSTOMIZATIONS, data: {turbolinks_track: "reload"}) unless Spree::Backend.propshaft?

        entries =
          if admin_asset_exists?("#{CUSTOMIZATIONS}.js")
            admin_propshaft_manifest.expand(CUSTOMIZATIONS, "js")
          else
            %w[jquery3 rails-ujs spree/backend].flat_map { |path| admin_propshaft_manifest.expand(path, "js") }
          end

        safe_join(entries.map { |entry| admin_propshaft_javascript_tag(entry) }, "\n")
      end

      def admin_asset_exists?(logical_path)
        if Spree::Backend.propshaft?
          Rails.application.assets.load_path.find(logical_path).present?
        else
          Rails.application.assets&.find_asset(logical_path).present? ||
            Rails.application.assets_manifest.assets.key?(logical_path)
        end
      end

      private

      def admin_propshaft_manifest
        Spree::Backend::PropshaftManifest.new(
          Rails.application.assets.load_path,
          aliases: {"css" => {"spree/backend" => Spree::Backend.dartsass_output("classic")}}
        )
      end

      def admin_propshaft_javascript_tag(entry)
        case entry.kind
        when :file
          javascript_include_tag(entry.logical_path, data: {turbolinks_track: "reload"})
        when :erb
          javascript_tag(ERB.new(entry.asset.content).result, nonce: true)
        when :template
          name = entry.logical_path.sub(%r{\A.*?templates/}, "").delete_suffix(".hbs")
          template = "Handlebars.compile(#{entry.asset.content.chomp.to_json})"

          if File.basename(name).start_with?("_")
            javascript_tag("Handlebars.registerPartial(#{name.to_json}, #{template});", nonce: true)
          else
            javascript_tag("window.HandlebarsTemplates = window.HandlebarsTemplates || {}; window.HandlebarsTemplates[#{name.to_json}] = #{template};", nonce: true)
          end
        end
      end
    end
  end
end
