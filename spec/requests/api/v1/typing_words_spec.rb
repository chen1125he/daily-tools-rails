# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Typing Words API', type: :request do
  path '/api/v1/typing_words/lookup' do
    get 'Lookup wubi code for a character' do
      tags 'TypingWords'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :character, in: :query, schema: { type: :string }, required: true

      response '200', 'from existing typing word' do
        let!(:user) { create(:user) }
        let!(:word) { create(:typing_word, character: '春', wubi_code: 'dwu') }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:character) { '春' }

        run_test! do |_response|
          data = json['data']
          expect(data['id']).to eq(word.id)
          expect(data['character']).to eq('春')
          expect(data['wubi_code']).to eq('dwu')
        end
      end

      response '400', 'character missing' do
        let!(:user) { create(:user) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:character) { '' }

        run_test! do |_response|
          expect(json['error']['code']).to eq('INVALID_PARAMS')
        end
      end

      response '404', 'typing word not found' do
        let!(:user) { create(:user) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:character) { '春' }

        run_test! do |_response|
          expect(json['error']['code']).to eq('TYPING_WORD_NOT_FOUND')
        end
      end
    end
  end
end
