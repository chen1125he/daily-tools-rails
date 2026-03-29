# frozen_string_literal: true

node(:total_pages) { @pagy.pages }
node(:current_page) { @pagy.page }
node(:total_count) { @pagy.count }
node(:next_page) { @pagy.next }
