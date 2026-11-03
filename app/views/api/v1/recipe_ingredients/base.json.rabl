# frozen_string_literal: true

attributes :id, :role, :amount

node(:role_label) { |ri| Recipe::ROLE_LABELS[ri.role] }

child(:ingredient) do
  extends 'api/v1/ingredients/base'
end
