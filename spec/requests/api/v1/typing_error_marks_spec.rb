# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Typing Error Marks API', type: :request do
  path '/api/v1/typing_error_marks' do
    get 'List recent error marks' do
      tags 'TypingErrorMarks'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :limit, in: :query, schema: { type: :integer }, required: false

      response '200', 'ok' do
        let!(:user) { create(:user) }
        let!(:other) { create(:user) }
        let!(:word_a) { create(:typing_word, character: '春') }
        let!(:word_b) { create(:typing_word, character: '眠') }
        let!(:word_c) { create(:typing_word, character: '晓') }
        let!(:high) do
          TypingErrorMark.create!(user: user, typing_word: word_a, mistake_count: 5, recent_mistake_count: 3)
        end
        let!(:mid) do
          TypingErrorMark.create!(user: user, typing_word: word_b, mistake_count: 2, recent_mistake_count: 1)
        end
        let!(:cleared) do
          TypingErrorMark.create!(user: user, typing_word: word_c, mistake_count: 4, recent_mistake_count: 0)
        end
        let!(:theirs) do
          TypingErrorMark.create!(user: other, typing_word: word_a, mistake_count: 9, recent_mistake_count: 9)
        end
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:limit) { 10 }

        run_test! do |response|
          items = json['data']
          expect(items.map { |row| row['id'] }).to eq([ high.id, mid.id ])
          expect(items.first).to include(
            'id' => high.id,
            'mistake_count' => 5,
            'recent_mistake_count' => 3,
            'character' => '春'
          )
          expect(items.first).not_to have_key('typing_word')
        end
      end
    end

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

  path '/api/v1/typing_error_marks/clear_recent' do
    post 'Clear recent mistake counts' do
      tags 'TypingErrorMarks'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: [ 'ids' ],
        properties: {
          ids: { type: :array, items: { type: :integer } }
        }
      }

      response '200', 'cleared' do
        let!(:user) { create(:user) }
        let!(:other) { create(:user) }
        let!(:word_a) { create(:typing_word, character: '春') }
        let!(:word_b) { create(:typing_word, character: '眠') }
        let!(:mine) do
          TypingErrorMark.create!(user: user, typing_word: word_a, mistake_count: 5, recent_mistake_count: 3)
        end
        let!(:theirs) do
          TypingErrorMark.create!(user: other, typing_word: word_b, mistake_count: 2, recent_mistake_count: 2)
        end
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:payload) { { ids: [ mine.id, theirs.id ] } }

        run_test! do |response|
          expect(json['data']['updated_count']).to eq(1)
          expect(mine.reload.recent_mistake_count).to eq(0)
          expect(mine.mistake_count).to eq(5)
          expect(theirs.reload.recent_mistake_count).to eq(2)
        end
      end

      response '400', 'ids blank' do
        let!(:user) { create(:user) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:payload) { { ids: [] } }

        run_test! do |response|
          expect(json['error']['code']).to eq('INVALID_PARAMS')
        end
      end
    end
  end
end
