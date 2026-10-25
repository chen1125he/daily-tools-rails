# frozen_string_literal: true

Rabl.configure do |config|
  # Keep top-level root keys (for example, `data`).
  config.include_json_root = true
  # Do not wrap child collection items with `datum`.
  config.include_child_root = false
end
