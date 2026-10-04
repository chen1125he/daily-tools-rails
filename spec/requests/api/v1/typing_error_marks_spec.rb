# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Typing Error Marks API', type: :request do
  path '/api/v1/typing_practices/{typing_practice_id}/error_marks' do
    parameter name: :typing_practice_id, in: :path, schema: { type: :integer }

    post 'Create or increment an error mark' do
      tags 'TypingErrorMarks'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: [ 'typing_error_mark' ],
        properties: {
          typing_error_mark: {
            type: :object,
            required: %w[character],
            properties: {
              character: { type: :string },
              wubi_code: { type: :string }
            }
          }
        }
      }

      response '201', 'created' do
        let!(:user) { create(:user) }
        let!(:practice) { create(:typing_practice, user: user, started_at: Time.current) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:typing_practice_id) { practice.id }
        let(:payload) { { typing_error_mark: { character: '春', wubi_code: 'dwu' } } }

        run_test! do |response|
          data = json['data']
          expect(data['mistake_count']).to eq(1)
          expect(data['typing_word']['character']).to eq('春')
          expect(data['typing_word']['wubi_code']).to eq('dwu')
        end
      end

      response '201', 'incremented when exists' do
        let!(:user) { create(:user) }
        let!(:practice) { create(:typing_practice, user: user, started_at: Time.current) }
        let!(:word) { create(:typing_word, character: '春', wubi_code: 'dwu') }
        let!(:mark) { TypingErrorMark.create!(typing_practice: practice, typing_word: word, mistake_count: 1) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:typing_practice_id) { practice.id }
        let(:payload) { { typing_error_mark: { character: '春' } } }

        run_test! do |response|
          expect(json['data']['id']).to eq(mark.id)
          expect(json['data']['mistake_count']).to eq(2)
        end
      end

      response '422', 'already finished' do
        let!(:user) { create(:user) }
        let!(:practice) do
          create(:typing_practice, user: user, started_at: 1.minute.ago, finished_at: Time.current)
        end
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:typing_practice_id) { practice.id }
        let(:payload) { { typing_error_mark: { character: '春' } } }

        run_test! do |response|
          expect(json['error']['code']).to eq('TYPING_PRACTICE_ALREADY_FINISHED')
        end
      end
    end
  end
end
