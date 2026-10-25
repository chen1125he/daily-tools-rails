# frozen_string_literal: true

class RenameContributionPointsToPoints < ActiveRecord::Migration[8.1]
  def change
    rename_column :chore_records, :contribution_points, :points
    rename_column :chores, :default_contribution_points, :default_points
  end
end
