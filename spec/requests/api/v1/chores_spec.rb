# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Chores API', type: :request do
  path '/api/v1/chores' do
    get 'List chores' do
      tags 'Chores'
      produces 'application/json'
      security [{ bearerAuth: [] }]
      parameter name: :Authorization, in: :header, schema: { type: :string }

      response '200', 'ok' do
        let!(:user) { create(:user) }
        let!(:active_chore) { create(:chore, name: '做饭', active: true) }
        let!(:inactive_chore) { create(:chore, name: '拖地', active: false) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }

        run_test! do |response|
          data = response.parsed_body['data']
          expect(data.size).to eq(2)
          expect(data.first['name']).to eq('做饭')
          expect(data.last['name']).to eq('拖地')
        end
      end
    end

    post 'Create a chore' do
      tags 'Chores'
      consumes 'application/json'
      produces 'application/json'
      security [{ bearerAuth: [] }]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: ['name'],
        properties: {
          name: { type: :string },
          active: { type: :boolean },
          description: { type: :string, nullable: true },
          default_points: { type: :number, nullable: true }
        }
      }

      response '201', 'created' do
        let!(:user) { create(:user) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:payload) { { name: '洗碗', default_points: 0.5 } }

        run_test! do |response|
          data = response.parsed_body['data']
          expect(data['name']).to eq('洗碗')
          expect(data['default_points']).to eq(0.5)
        end
      end
    end
  end

  path '/api/v1/chores/{id}' do
    get 'Show a chore' do
      tags 'Chores'
      produces 'application/json'
      security [{ bearerAuth: [] }]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :integer }

      response '200', 'ok' do
        let!(:user) { create(:user) }
        let!(:chore) { create(:chore, name: '洗碗', default_points: 1.5) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:id) { chore.id }

        run_test! do |response|
          data = response.parsed_body['data']
          expect(data['id']).to eq(chore.id)
          expect(data['name']).to eq('洗碗')
          expect(data['default_points']).to eq(1.5)
        end
      end

      response '404', 'not found' do
        let!(:user) { create(:user) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:id) { 999_999 }

        run_test! do |response|
          error = response.parsed_body['error']
          expect(error['code']).to eq('CHORE_NOT_FOUND')
        end
      end
    end

    put 'Update a chore' do
      tags 'Chores'
      consumes 'application/json'
      produces 'application/json'
      security [{ bearerAuth: [] }]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :integer }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          active: { type: :boolean },
          description: { type: :string, nullable: true }
        }
      }

      response '200', 'updated' do
        let!(:user) { create(:user) }
        let!(:chore) { create(:chore, active: true) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:id) { chore.id }
        let(:payload) { { active: false, description: '手动下线' } }

        run_test! do |response|
          data = response.parsed_body['data']
          expect(data['active']).to eq(false)
          expect(data['description']).to eq('手动下线')
        end
      end
    end
  end
end
