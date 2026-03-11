module Authenticatable
  extend ActiveSupport::Concern

  included do
    attr_reader :current_user
  end

  def authenticate_user!
    token = bearer_token
    payload = Auth::TokenVerifier.verify_access_token(token)
    return render_auth_error("AUTH_TOKEN_INVALID", "token 无效") unless payload

    user = User.find_by(id: payload[:sub])
    return render_auth_error("AUTH_TOKEN_INVALID", "token 无效") unless user&.active?

    @current_user = user
  end

  private

  def bearer_token
    request.authorization.to_s.split(" ", 2).last
  end

  def render_auth_error(code, message, status: :unauthorized)
    render json: { error: { code: code, message: message } }, status: status
  end
end
