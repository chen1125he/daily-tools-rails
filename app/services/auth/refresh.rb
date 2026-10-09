# frozen_string_literal: true

module Auth
  class Refresh
    Result = Struct.new(:success?, :payload, :error_code, :error_message, keyword_init: true)

    class << self
      def call(refresh_token:, ip: nil, device_info: nil)
        record = RefreshToken.find_by(token_digest: RefreshToken.digest(refresh_token))
        return invalid_refresh_token unless record&.active?
        return user_disabled unless record.user.active?

        ActiveRecord::Base.transaction do
          record.revoke!
          tokens = TokenIssuer.issue_pair(user: record.user, ip: ip, device_info: device_info)

          Result.new(success?: true, payload: tokens)
        end
      end

      private

      def invalid_refresh_token
        Result.new(
          success?: false,
          error_code: 'AUTH_REFRESH_TOKEN_INVALID',
          error_message: 'refresh token 无效或已过期'
        )
      end

      def user_disabled
        Result.new(
          success?: false,
          error_code: 'AUTH_USER_DISABLED',
          error_message: '用户已被禁用'
        )
      end
    end
  end
end
