# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Chore Records API', type: :request do
  path '/api/v1/chore_records' do
    post 'Create chore record from text' do
      tags 'ChoreRecords'
      consumes 'application/json'
      produces 'application/json'
      security [{ bearerAuth: [] }]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: ['text'],
        properties: {
          text: { type: :string },
          creator_id: { type: :integer }
        }
      }

      response '201', 'created' do
        let!(:user) { create(:user, name: '小红') }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:payload) { { text: '昨晚我做饭 1.5 小时', creator_id: user.id } }

        run_test! do |response|
          data = response.parsed_body['data']
          meta = response.parsed_body['meta']
          expect(data['chore_name']).to eq('做饭')
          expect(data['contribution_points']).to eq(1.5)
          expect(meta).to include('ai_confidence', 'needs_review')
        end
      end

      response '422', 'parse failed' do
        let!(:user) { create(:user, name: '小红') }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:payload) { { text: '' } }

        run_test! do |response|
          expect(response.parsed_body['error']['code']).to eq('CHORE_RECORD_PARSE_FAILED')
        end
      end
    end

    get 'List chore records' do
      tags 'ChoreRecords'
      produces 'application/json'
      security [{ bearerAuth: [] }]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :performer_id, in: :query, schema: { type: :integer }
      parameter name: :chore_name, in: :query, schema: { type: :string }

      response '200', 'ok' do
        let!(:user) { create(:user, name: '创建者') }
        let!(:performed_user) { create(:user, name: '执行者') }
        let!(:cook_chore) { create(:chore, name: '做饭') }
        let!(:clean_chore) { create(:chore, name: '拖地') }
        let!(:matched) do
          create(:chore_record, chore: cook_chore, performer: performed_user, creator: user, performed_at: Time.zone.parse('2026-03-08 20:00:00'))
        end
        let!(:unmatched) do
          create(:chore_record, chore: clean_chore, performer: user, creator: user, performed_at: Time.zone.parse('2026-03-08 21:00:00'))
        end
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:performer_id) { performed_user.id }
        let(:chore_name) { '做' }

        run_test! do |response|
          data = response.parsed_body['data']
          expect(data.map { |item| item['id'] }).to contain_exactly(matched.id)
          expect(response.parsed_body['meta']['total']).to eq(1)
        end
      end
    end
  end

  path '/api/v1/chore_records/{id}' do
    get 'Show chore record' do
      tags 'ChoreRecords'
      produces 'application/json'
      security [{ bearerAuth: [] }]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :integer }

      response '200', 'ok' do
        let!(:user) { create(:user, name: '创建者') }
        let!(:chore_record) { create(:chore_record, creator: user, performer: user) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:id) { chore_record.id }

        run_test! do |response|
          expect(response.parsed_body['data']['id']).to eq(chore_record.id)
        end
      end
    end

    put 'Update chore record' do
      tags 'ChoreRecords'
      consumes 'application/json'
      produces 'application/json'
      security [{ bearerAuth: [] }]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :integer }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          contribution_points: { type: :number }
        }
      }

      response '200', 'updated' do
        let!(:user) { create(:user, name: '创建者') }
        let!(:chore_record) { create(:chore_record, creator: user, performer: user, contribution_points: 1.0) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:id) { chore_record.id }
        let(:payload) { { contribution_points: 2.5 } }

        run_test! do |response|
          expect(response.parsed_body['data']['contribution_points']).to eq(2.5)
        end
      end
    end

    delete 'Delete chore record' do
      tags 'ChoreRecords'
      security [{ bearerAuth: [] }]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :integer }

      response '204', 'deleted' do
        let!(:user) { create(:user, name: '创建者') }
        let!(:chore_record) { create(:chore_record, creator: user, performer: user) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:id) { chore_record.id }

        run_test!
      end
    end
  end
end
