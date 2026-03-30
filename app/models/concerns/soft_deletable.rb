# frozen_string_literal: true

module SoftDeletable
  extend ActiveSupport::Concern

  included do
    scope :present, -> { where(removed_at: nil) }
    scope :removed, -> { unscoped.where.not(removed_at: nil) }

    def self.revoke_collection
      update_all(removed_at: nil, updated_at: Time.current)
    end
  end

  def removed?
    removed_at.present?
  end

  # 直接更新时间，免得触发回调
  def remove
    update_columns(removed_at: Time.current, updated_at: Time.current)
  end

  # 直接更新时间，免得触发回调
  def revoke
    update_columns(removed_at: nil, updated_at: Time.current)
  end
end
