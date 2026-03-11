# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController
      before_action :authenticate_user!, only: %i[me sign_out password]

      def sign_in
        result = Auth::SignIn.call(
          phone: sign_in_params[:phone],
          password: sign_in_params[:password],
          ip: request.remote_ip,
          device_info: request.user_agent
        )

        return render_auth_result_error(result) unless result.success?

        render json: { data: result.payload }, status: :ok
      end

      def refresh
        result = Auth::Refresh.call(
          refresh_token: refresh_params[:refresh_token],
          ip: request.remote_ip,
          device_info: request.user_agent
        )

        return render_auth_result_error(result) unless result.success?

        render json: { data: result.payload }, status: :ok
      end

      def me
        render json: {
          data: {
            id: current_user.id,
            phone: current_user.phone,
            name: current_user.name
          }
        }, status: :ok
      end

      def sign_out
        token = RefreshToken.find_by(token_digest: RefreshToken.digest(sign_out_params[:refresh_token]))
        token&.revoke! if token&.user_id == current_user.id && token.active?

        head :no_content
      end

      def password
        unless current_user.authenticate(password_params[:current_password])
          return render_auth_error('AUTH_INVALID_CREDENTIALS', '当前密码错误', status: :unprocessable_content)
        end

        unless current_user.update(password_params.slice(:password, :password_confirmation))
          return render_validation_error(current_user)
        end

        current_user.refresh_tokens.active.find_each(&:revoke!)
        head :no_content
      end

      private

      def sign_in_params
        params.permit(:phone, :password)
      end

      def refresh_params
        params.permit(:refresh_token)
      end

      def sign_out_params
        params.permit(:refresh_token)
      end

      def password_params
        params.permit(:current_password, :password, :password_confirmation)
      end

      def render_auth_result_error(result)
        status = result.error_code == 'AUTH_USER_DISABLED' ? :forbidden : :unauthorized
        render_auth_error(result.error_code, result.error_message, status: status)
      end

      def render_validation_error(record)
        render json: {
          error: {
            code: 'AUTH_PASSWORD_WEAK',
            message: record.errors.full_messages.to_sentence
          }
        }, status: :unprocessable_content
      end
    end
  end
end
