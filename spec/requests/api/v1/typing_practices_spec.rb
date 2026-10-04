# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Typing Practices API', type: :request do
  path '/api/v1/typing_practices' do
    get 'List typing practices' do
      tags 'TypingPractices'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :typing_article_id, in: :query, schema: { type: :integer }, required: false
      parameter name: :page, in: :query, schema: { type: :integer }, required: false
      parameter name: :limit, in: :query, schema: { type: :integer }, required: false

      response '200', 'ok' do
        let!(:user) { create(:user) }
        let!(:other) { create(:user) }
        let!(:article) { create(:typing_article) }
        let!(:mine) { create(:typing_practice, user: user, typing_article: article) }
        let!(:theirs) { create(:typing_practice, user: other, typing_article: article) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }

        run_test! do |response|
          ids = json['data']['items'].map { |row| row['id'] }
          expect(ids).to contain_exactly(mine.id)
        end
      end
    end

    post 'Create a typing practice' do
      tags 'TypingPractices'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: [ 'typing_practice' ],
        properties: {
          typing_practice: {
            type: :object,
            required: %w[typing_article_id],
            properties: {
              typing_article_id: { type: :integer }
            }
          }
        }
      }

      response '201', 'created' do
        let!(:user) { create(:user) }
        let!(:article) { create(:typing_article) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:payload) { { typing_practice: { typing_article_id: article.id } } }

        run_test! do |response|
          data = json['data']
          expect(data['typing_article_id']).to eq(article.id)
          expect(data['status']).to eq('pending')
          expect(data['started_at']).to be_nil
        end
      end
    end
  end

  path '/api/v1/typing_practices/{id}/start' do
    parameter name: :id, in: :path, schema: { type: :integer }

    post 'Start a typing practice' do
      tags 'TypingPractices'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :Authorization, in: :header, schema: { type: :string }

      response '200', 'started' do
        let!(:user) { create(:user) }
        let!(:practice) { create(:typing_practice, user: user) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:id) { practice.id }

        run_test! do |response|
          expect(json['data']['status']).to eq('in_progress')
          expect(json['data']['started_at']).to be_present
        end
      end

      response '422', 'already started' do
        let!(:user) { create(:user) }
        let!(:practice) { create(:typing_practice, user: user, started_at: Time.current) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:id) { practice.id }

        run_test! do |response|
          expect(json['error']['code']).to eq('VALIDATION_FAILED')
        end
      end
    end
  end

  path '/api/v1/typing_practices/{id}/complete' do
    parameter name: :id, in: :path, schema: { type: :integer }

    post 'Complete a typing practice' do
      tags 'TypingPractices'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: [ 'typing_practice' ],
        properties: {
          typing_practice: {
            type: :object,
            required: %w[typed_body],
            properties: {
              typed_body: { type: :string }
            }
          }
        }
      }

      response '200', 'completed' do
        let!(:user) { create(:user) }
        let!(:article) { create(:typing_article, body: '春眠不觉晓') }
        let!(:practice) { create(:typing_practice, user: user, typing_article: article, started_at: 1.minute.ago) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:id) { practice.id }
        let(:payload) { { typing_practice: { typed_body: '春眠不学晓' } } }

        run_test! do |response|
          data = json['data']
          expect(data['status']).to eq('completed')
          expect(data['typed_body']).to eq('春眠不学晓')
          expect(data['correct_count']).to eq(4)
          expect(data['error_count']).to eq(1)
          expect(data['accuracy'].to_f).to eq(80.0)
          expect(data['duration_ms']).to be_within(2_000).of(60_000)
          expect(data['cpm'].to_f).to be > 0
          expect(data['finished_at']).to be_present
        end
      end

      response '422', 'not started' do
        let!(:user) { create(:user) }
        let!(:practice) { create(:typing_practice, user: user) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:id) { practice.id }
        let(:payload) { { typing_practice: { typed_body: '春眠不觉晓' } } }

        run_test! do |response|
          expect(json['error']['code']).to eq('VALIDATION_FAILED')
        end
      end
    end
  end
end
