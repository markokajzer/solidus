# frozen_string_literal: true

module Spree
  module Backend
    # Propshaft serves files as they are, so the Sprockets directives in the
    # backend's manifests (and in the app's spree/backend/all.*) are expanded
    # here into the same files, in the same order, that Sprockets would have
    # concatenated.
    class PropshaftManifest
      DIRECTIVE = %r{\A\s*(?://|\*)=\s*(require_self|require_tree|require)\b\s*['"]?([^'"\s]*)['"]?\s*\z}

      CANDIDATES = {
        "js" => ["%s.js", "%s.js.erb", "%s.hbs", "%s/index.js", "%s"],
        "css" => ["%s.css", "%s/index.css", "%s"]
      }.freeze

      TREE = {
        "js" => /\.(js|js\.erb|hbs)\z/,
        "css" => /\.css\z/
      }.freeze

      Entry = Data.define(:kind, :logical_path, :asset)

      def initialize(load_path, aliases: {})
        @load_path = load_path
        @aliases = aliases
      end

      def expand(logical_path, extension)
        entries = []
        require_path(logical_path, extension, nil, entries, Set.new)
        entries
      end

      private

      def require_path(logical_path, extension, from, entries, seen)
        if (aliased = @aliases.dig(extension, logical_path))
          entries << Entry.new(kind: :file, logical_path: aliased, asset: nil) if seen.add?(logical_path)
        else
          include_asset(find(logical_path, extension, from), extension, entries, seen)
        end
      end

      def include_asset(asset, extension, entries, seen)
        return unless seen.add?(asset.logical_path.to_s)

        case asset.logical_path.extname
        when ".hbs" then return entries << Entry.new(kind: :template, logical_path: asset.logical_path.to_s, asset:)
        when ".scss", ".sass" then return
        end

        kind = (asset.logical_path.extname == ".erb") ? :erb : :file
        self_entry = Entry.new(kind:, logical_path: asset.logical_path.to_s, asset:)
        self_included = false

        asset.content.each_line do |line|
          directive, argument = line.match(DIRECTIVE)&.captures

          case directive
          when "require"
            require_path(argument, extension, asset, entries, seen)
          when "require_self"
            entries << self_entry
            self_included = true
          when "require_tree"
            tree(asset, argument, extension).each { |child| include_asset(child, extension, entries, seen) }
          end
        end

        entries << self_entry unless self_included
      end

      def find(logical_path, extension, from)
        path = (from && logical_path.start_with?(".")) ? from.logical_path.dirname.join(logical_path).cleanpath.to_s : logical_path

        CANDIDATES.fetch(extension).each do |pattern|
          asset = @load_path.find(format(pattern, path))
          return asset if asset
        end

        raise Propshaft::MissingAssetError.new(logical_path)
      end

      def tree(asset, directory, extension)
        prefix = asset.logical_path.dirname.join(directory).cleanpath.to_s
        prefix = (prefix == ".") ? "" : "#{prefix}/"

        @load_path.assets
          .select { |child| child.logical_path.to_s.start_with?(prefix) && child.logical_path.to_s.match?(TREE.fetch(extension)) }
          .sort_by { |child| child.logical_path.to_s }
      end
    end
  end
end
