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

      let(:ai_result) { { wubi_code: 'dwu', wubi_roots: %w[三 人 日] } }

      response '200', 'from existing typing word' do
        let!(:user) { create(:user) }
        let!(:word) { create(:typing_word, character: '春', wubi_code: 'dwu', wubi_roots: %w[三 人 日]) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:character) { '春' }

        before { allow(Ai::WubiCodeLookup).to receive(:call) }

        run_test! do |response|
          data = json['data']
          expect(data['id']).to eq(word.id)
          expect(data['character']).to eq('春')
          expect(data['wubi_code']).to eq('dwu')
          expect(data['wubi_roots']).to eq(%w[三 人 日])
          expect(Ai::WubiCodeLookup).not_to have_received(:call)
        end
      end

      response '200', 'fills missing wubi via AI' do
        let!(:user) { create(:user) }
        let!(:word) { TypingWord.create!(character: '春') }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:character) { '春' }

        before { allow(Ai::WubiCodeLookup).to receive(:call).with(character: '春').and_return(ai_result) }

        run_test! do |response|
          data = json['data']
          expect(data['id']).to eq(word.id)
          expect(data['wubi_code']).to eq('dwu')
          expect(data['wubi_roots']).to eq(%w[三 人 日])
          expect(word.reload.wubi_roots).to eq(%w[三 人 日])
        end
      end

      response '200', 'creates typing word via AI' do
        let!(:user) { create(:user) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:character) { '春' }

        before { allow(Ai::WubiCodeLookup).to receive(:call).with(character: '春').and_return(ai_result) }

        run_test! do |response|
          data = json['data']
          expect(data['character']).to eq('春')
          expect(data['wubi_code']).to eq('dwu')
          expect(data['wubi_roots']).to eq(%w[三 人 日])
          expect(TypingWord.find_by!(character: '春').wubi_roots).to eq(%w[三 人 日])
        end
      end

      response '400', 'character missing' do
        let!(:user) { create(:user) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:character) { '' }

        run_test! do |response|
          expect(json['error']['code']).to eq('INVALID_PARAMS')
        end
      end

      response '422', 'ai lookup failed' do
        let!(:user) { create(:user) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:character) { '春' }

        before do
          allow(Ai::WubiCodeLookup).to receive(:call).and_raise(Ai::WubiCodeLookup::ParseError, 'AI 响应为空')
        end

        run_test! do |response|
          expect(json['error']['code']).to eq('WUBI_LOOKUP_FAILED')
          expect(TypingWord.find_by(character: '春')).to be_nil
        end
      end
    end
  end
end
