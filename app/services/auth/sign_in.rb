# frozen_string_literal: true

module Auth
  class SignIn
    Result = Struct.new(:success?, :payload, :error_code, :error_message, keyword_init: true)

    class << self
      def call(phone:, password:, ip: nil, device_info: nil)
        user = User.find_by(phone: phone)
        return invalid_credentials unless user&.authenticate(password)
        return user_disabled unless user.active?

        tokens = TokenIssuer.issue_pair(user: user, ip: ip, device_info: device_info)
        user.update!(last_sign_in_at: Time.current, last_sign_in_ip: ip)

        Result.new(
          success?: true,
          payload: tokens.merge(
            user: {
              id: user.id,
              phone: user.phone,
              name: user.name
            }
          )
        )
      end

      private

      def invalid_credentials
        Result.new(
          success?: false,
          error_code: 'AUTH_INVALID_CREDENTIALS',
          error_message: '手机号或密码错误'
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
