# frozen_string_literal: true

require "securerandom"

module Auth
  class TokenIssuer
    ACCESS_TOKEN_TTL = 2.hours
    REFRESH_TOKEN_TTL = 30.days

    class << self
      def issue_pair(user:, ip: nil, device_info: nil)
        access_token = issue_access_token(user)
        refresh_token = issue_refresh_token(user: user, ip: ip, device_info: device_info)

        {
          access_token: access_token,
          expires_in: ACCESS_TOKEN_TTL.to_i,
          refresh_token: refresh_token[:token],
          refresh_expires_in: REFRESH_TOKEN_TTL.to_i
        }
      end

      private

      def issue_access_token(user)
        payload = {
          sub: user.id,
          scope: "access",
          jti: SecureRandom.uuid,
          iat: Time.current.to_i,
          exp: ACCESS_TOKEN_TTL.from_now.to_i
        }

        JWT.encode(payload, jwt_secret, "HS256")
      end

      def issue_refresh_token(user:, ip:, device_info:)
        raw_token = SecureRandom.hex(64)

        RefreshToken.create!(
          user: user,
          token_digest: RefreshToken.digest(raw_token),
          expires_at: REFRESH_TOKEN_TTL.from_now,
          ip: ip,
          device_info: device_info
        )

        { token: raw_token }
      end

      def jwt_secret
        Rails.application.secret_key_base
      end
    end
  end
end
