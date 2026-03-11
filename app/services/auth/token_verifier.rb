module Auth
  class TokenVerifier
    class << self
      def verify_access_token(token)
        payload, = JWT.decode(token, jwt_secret, true, { algorithm: "HS256" })

        return nil unless payload["scope"] == "access"

        payload.with_indifferent_access
      rescue JWT::DecodeError
        nil
      end

      private

      def jwt_secret
        Rails.application.secret_key_base
      end
    end
  end
end
