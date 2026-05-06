# frozen_string_literal: true

# Shared JSON error helpers for API controllers.
module ApiResponses
  extend ActiveSupport::Concern

  private

  def render_not_found(code, message)
    render json: { error: { code: code, message: message } }, status: :not_found
  end

  # +code+ / +include_details+ allow endpoints that need a stable client-facing code (e.g. password flow)
  # without exposing +details+.
  def render_validation_error(record, code: 'VALIDATION_FAILED', include_details: true)
    error = {
      code: code,
      message: record.errors.full_messages.to_sentence
    }
    error[:details] = record.errors.to_hash if include_details

    render json: { error: error }, status: :unprocessable_content
  end

  def render_auth_error(code, message, status: :unauthorized)
    render json: { error: { code: code, message: message } }, status: status
  end
end
