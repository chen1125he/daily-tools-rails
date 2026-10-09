# frozen_string_literal: true

# Success JSON shape for API clients: { "code": 0, "data": ..., "message": optional }
module ApiEnvelope
  extend ActiveSupport::Concern

  private

  def render_api_success(data, status: :ok, message: nil)
    body = { code: 0, data: data }
    body[:message] = message if message.present?
    render json: body, status: status
  end
end
