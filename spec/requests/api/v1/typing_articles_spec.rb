# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Typing Articles API', type: :request do
  path '/api/v1/typing_articles' do
    get 'List typing articles' do
      tags 'TypingArticles'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :page, in: :query, schema: { type: :integer }, required: false
      parameter name: :limit, in: :query, schema: { type: :integer }, required: false

      response '200', 'ok' do
        let!(:user) { create(:user) }
        let!(:article) { create(:typing_article, title: '春晓') }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }

        run_test! do |response|
          items = json['data']['items']
          expect(items.map { |row| row['title'] }).to include('春晓')
        end
      end
    end

    post 'Create a typing article' do
      tags 'TypingArticles'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: [ 'typing_article' ],
        properties: {
          typing_article: {
            type: :object,
            required: %w[title body],
            properties: {
              title: { type: :string },
              body: { type: :string }
            }
          }
        }
      }

      response '201', 'created' do
        let!(:user) { create(:user) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:payload) { { typing_article: { title: '静夜思', body: '床前明月光' } } }

        run_test! do |response|
          data = json['data']
          expect(data['title']).to eq('静夜思')
          expect(data['body']).to eq('床前明月光')
        end
      end
    end
  end

  path '/api/v1/typing_articles/{id}' do
    parameter name: :id, in: :path, schema: { type: :integer }

    get 'Show a typing article' do
      tags 'TypingArticles'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :Authorization, in: :header, schema: { type: :string }

      response '200', 'ok' do
        let!(:user) { create(:user) }
        let!(:article) { create(:typing_article, title: '登鹳雀楼') }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:id) { article.id }

        run_test! do |response|
          expect(json['data']['title']).to eq('登鹳雀楼')
        end
      end

      response '404', 'not found' do
        let!(:user) { create(:user) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:id) { 999_999 }

        run_test! do |response|
          expect(json['error']['code']).to eq('TYPING_ARTICLE_NOT_FOUND')
        end
      end
    end

    put 'Update a typing article' do
      tags 'TypingArticles'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          typing_article: {
            type: :object,
            properties: {
              title: { type: :string },
              body: { type: :string }
            }
          }
        }
      }

      response '200', 'updated' do
        let!(:user) { create(:user) }
        let!(:article) { create(:typing_article, title: '旧标题') }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:id) { article.id }
        let(:payload) { { typing_article: { title: '新标题' } } }

        run_test! do |response|
          expect(json['data']['title']).to eq('新标题')
        end
      end
    end

    delete 'Delete a typing article' do
      tags 'TypingArticles'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :Authorization, in: :header, schema: { type: :string }

      response '200', 'deleted' do
        let!(:user) { create(:user) }
        let!(:article) { create(:typing_article) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:id) { article.id }

        run_test! do
          expect(TypingArticle.find_by(id: article.id)).to be_nil
        end
      end

      response '422', 'in use' do
        let!(:user) { create(:user) }
        let!(:article) { create(:typing_article) }
        let!(:practice) { create(:typing_practice, user: user, typing_article: article) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:id) { article.id }

        run_test! do |response|
          expect(json['error']['code']).to eq('TYPING_ARTICLE_IN_USE')
        end
      end
    end
  end
end
