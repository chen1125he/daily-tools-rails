# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Auth API", type: :request do
  path "/api/v1/auth/sign_in" do
    post "Sign in" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: %w[phone password],
        properties: {
          phone: { type: :string },
          password: { type: :string }
        }
      }

      response "200", "signed in" do
        let!(:user) { create(:user, phone: "13800000000", name: "Alice") }
        let(:payload) { { phone: user.phone, password: "Password123" } }

        run_test! do |response|
          expect(response.parsed_body["data"]).to include("access_token", "refresh_token", "expires_in", "refresh_expires_in")
          expect(user.reload.last_sign_in_at).not_to be_nil
        end
      end

      response "401", "invalid credentials" do
        let!(:user) { create(:user, phone: "13800000000", name: "Alice") }
        let(:payload) { { phone: user.phone, password: "WrongPassword123" } }

        run_test! do |response|
          expect(response.parsed_body).to eq(
            "error" => {
              "code" => "AUTH_INVALID_CREDENTIALS",
              "message" => "手机号或密码错误"
            }
          )
        end
      end

      response "403", "disabled user" do
        let!(:user) { create(:user, phone: "13800000000", name: "Alice", status: "disabled") }
        let(:payload) { { phone: user.phone, password: "Password123" } }

        run_test! do |response|
          expect(response.parsed_body).to eq(
            "error" => {
              "code" => "AUTH_USER_DISABLED",
              "message" => "用户已被禁用"
            }
          )
        end
      end
    end
  end

  path "/api/v1/auth/refresh" do
    post "Refresh access token" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: ["refresh_token"],
        properties: {
          refresh_token: { type: :string }
        }
      }

      response "200", "refreshed" do
        let!(:user) { create(:user, phone: "13800000001", name: "Bob") }
        let!(:issued_pair) { Auth::TokenIssuer.issue_pair(user: user, ip: "127.0.0.1", device_info: "rspec") }
        let!(:old_token_record) { RefreshToken.find_by!(token_digest: RefreshToken.digest(issued_pair[:refresh_token])) }
        let(:payload) { { refresh_token: issued_pair[:refresh_token] } }

        run_test! do |response|
          expect(response.parsed_body["data"]).to include("access_token", "refresh_token", "expires_in", "refresh_expires_in")
          expect(old_token_record.reload.revoked_at).not_to be_nil
        end
      end

      response "401", "invalid refresh token" do
        let(:payload) { { refresh_token: "invalid-token" } }

        run_test! do |response|
          expect(response.parsed_body).to eq(
            "error" => {
              "code" => "AUTH_REFRESH_TOKEN_INVALID",
              "message" => "refresh token 无效或已过期"
            }
          )
        end
      end

      response "403", "disabled user for token" do
        let!(:user) { create(:user, phone: "13800000001", name: "Bob", status: "disabled") }
        let!(:issued_pair) { Auth::TokenIssuer.issue_pair(user: user, ip: "127.0.0.1", device_info: "rspec") }
        let(:payload) { { refresh_token: issued_pair[:refresh_token] } }

        run_test! do |response|
          expect(response.parsed_body).to eq(
            "error" => {
              "code" => "AUTH_USER_DISABLED",
              "message" => "用户已被禁用"
            }
          )
        end
      end
    end
  end

  path "/api/v1/auth/me" do
    get "Get current user profile" do
      tags "Auth"
      produces "application/json"
      security [{ bearerAuth: [] }]
      parameter name: :Authorization, in: :header, schema: { type: :string }

      response "200", "ok" do
        let!(:user) { create(:user, phone: "13800000002", name: "Carol") }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }

        run_test! do |response|
          expect(response.parsed_body).to eq(
            "data" => {
              "id" => user.id,
              "phone" => user.phone,
              "name" => user.name
            }
          )
        end
      end

      response "401", "token invalid" do
        let(:Authorization) { nil }

        run_test! do |response|
          expect(response.parsed_body).to eq(
            "error" => {
              "code" => "AUTH_TOKEN_INVALID",
              "message" => "token 无效"
            }
          )
        end
      end
    end
  end

  path "/api/v1/auth/sign_out" do
    delete "Sign out" do
      tags "Auth"
      consumes "application/json"
      security [{ bearerAuth: [] }]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: ["refresh_token"],
        properties: {
          refresh_token: { type: :string }
        }
      }

      response "204", "signed out" do
        let!(:user) { create(:user, phone: "13800000003", name: "Dave") }
        let!(:issued_pair) { Auth::TokenIssuer.issue_pair(user: user) }
        let!(:token_record) { RefreshToken.find_by!(token_digest: RefreshToken.digest(issued_pair[:refresh_token])) }
        let(:Authorization) { "Bearer #{issued_pair[:access_token]}" }
        let(:payload) { { refresh_token: issued_pair[:refresh_token] } }

        run_test! do
          expect(token_record.reload.revoked_at).not_to be_nil
        end
      end
    end
  end

  path "/api/v1/auth/password" do
    patch "Update password" do
      tags "Auth"
      consumes "application/json"
      security [{ bearerAuth: [] }]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: %w[current_password password password_confirmation],
        properties: {
          current_password: { type: :string },
          password: { type: :string },
          password_confirmation: { type: :string }
        }
      }

      response "422", "current password incorrect" do
        let!(:user) { create(:user, phone: "13800000004", name: "Eve") }
        let!(:issued_pair) { Auth::TokenIssuer.issue_pair(user: user) }
        let(:Authorization) { "Bearer #{issued_pair[:access_token]}" }
        let(:payload) do
          {
            current_password: "WrongPassword123",
            password: "NewPassword123",
            password_confirmation: "NewPassword123"
          }
        end

        run_test! do |response|
          expect(response.parsed_body).to eq(
            "error" => {
              "code" => "AUTH_INVALID_CREDENTIALS",
              "message" => "当前密码错误"
            }
          )
        end
      end

      response "204", "password updated" do
        let!(:user) { create(:user, phone: "13800000004", name: "Eve") }
        let!(:pair_one) { Auth::TokenIssuer.issue_pair(user: user) }
        let!(:pair_two) { Auth::TokenIssuer.issue_pair(user: user) }
        let(:Authorization) { "Bearer #{pair_one[:access_token]}" }
        let(:payload) do
          {
            current_password: "Password123",
            password: "NewPassword123",
            password_confirmation: "NewPassword123"
          }
        end

        run_test! do
          expect(user.reload.authenticate("NewPassword123")).to be_truthy
          expect(user.refresh_tokens.active.count).to eq(0)
          expect(RefreshToken.find_by!(token_digest: RefreshToken.digest(pair_two[:refresh_token])).revoked_at).not_to be_nil
        end
      end
    end
  end
end
