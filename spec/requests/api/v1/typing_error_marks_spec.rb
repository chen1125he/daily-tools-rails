# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Typing Error Marks API', type: :request do
  path '/api/v1/typing_error_marks' do
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
              character: { type: :string }
            }
          }
        }
      }

      response '201', 'created' do
        let!(:user) { create(:user) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:payload) { { typing_error_mark: { character: '春' } } }

        run_test! do |response|
          data = json['data']
          expect(data['mistake_count']).to eq(1)
          expect(data['recent_mistake_count']).to eq(1)
          expect(data['user_id']).to eq(user.id)
          expect(data['typing_word']['character']).to eq('春')
          expect(data['typing_word']).not_to have_key('wubi_roots')
        end
      end

      response '201', 'incremented when exists' do
        let!(:user) { create(:user) }
        let!(:word) { create(:typing_word, character: '春', wubi_code: 'dwu') }
        let!(:mark) do
          TypingErrorMark.create!(
            user: user,
            typing_word: word,
            mistake_count: 1,
            recent_mistake_count: 1
          )
        end
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:payload) { { typing_error_mark: { character: '春' } } }

        run_test! do |response|
          expect(json['data']['id']).to eq(mark.id)
          expect(json['data']['mistake_count']).to eq(2)
          expect(json['data']['recent_mistake_count']).to eq(2)
        end
      end
    end
  end
end
