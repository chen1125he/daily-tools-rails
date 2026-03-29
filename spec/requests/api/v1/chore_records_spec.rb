# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Chore Records API', type: :request do
  include_context 'api request authentication helper methods'

  path '/api/v1/chore_records' do
    post 'Create chore record' do
      tags 'ChoreRecords'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: [ 'chore_record' ],
        properties: {
          chore_record: {
            type: :object,
            required: %w[chore_type points performer_id performed_at],
            properties: {
              chore_type: { type: :string, enum: %w[catalog custom] },
              chore_id: { type: :integer },
              custom_chore_name: { type: :string },
              points: { type: :number },
              performer_id: { type: :integer },
              performed_at: { type: :string },
              source_text: { type: :string }
            }
          }
        }
      }

      response '201', 'created catalog' do
        let!(:user) { create(:user, name: '创建者') }
        let!(:performer) { create(:user, name: '执行者') }
        let!(:chore) { create(:chore, name: '洗碗') }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:payload) do
          {
            chore_record: {
              chore_type: 'catalog',
              chore_id: chore.id,
              performer_id: performer.id,
              points: 2.5,
              performed_at: '2026-03-08T20:00:00Z',
              source_text: '手动录入'
            }
          }
        end

        run_test! do |response|
          expect(response).to have_http_status(:created)
          data = json['data']
          expect(data['chore_type']).to eq('catalog')
          expect(data['chore_id']).to eq(chore.id)
          expect(data['chore_name']).to eq('洗碗')
          expect(data['performer_id']).to eq(performer.id)
          expect(data['creator_id']).to eq(user.id)
          expect(data['points']).to eq('2.5')
          expect(data['source_text']).to eq('手动录入')
        end
      end

      response '201', 'created custom' do
        let!(:user) { create(:user, name: '创建者') }
        let!(:performer) { create(:user, name: '执行者') }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:payload) do
          {
            chore_record: {
              chore_type: 'custom',
              custom_chore_name: '整理地下室',
              performer_id: performer.id,
              points: 1.0,
              performed_at: '2026-03-09T10:00:00Z'
            }
          }
        end

        run_test! do |response|
          expect(response).to have_http_status(:created)
          data = json['data']
          expect(data['chore_type']).to eq('custom')
          expect(data['chore_id']).to be_nil
          expect(data['custom_chore_name']).to eq('整理地下室')
          expect(data['chore_name']).to eq('整理地下室')
          expect(data['points']).to eq('1.0')
        end
      end

      response '422', 'validation failed' do
        let!(:user) { create(:user, name: '创建者') }
        let!(:performer) { create(:user, name: '执行者') }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:payload) do
          {
            chore_record: {
              chore_type: 'catalog',
              chore_id: nil,
              performer_id: performer.id,
              points: 1.0,
              performed_at: '2026-03-09T10:00:00Z'
            }
          }
        end

        run_test! do |response|
          expect(response).to have_http_status(422)
          expect(json['error']['code']).to eq('VALIDATION_FAILED')
        end
      end
    end

    get 'List chore records' do
      tags 'ChoreRecords'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :performer_id, in: :query, schema: { type: :integer }, required: false
      parameter name: :chore_id, in: :query, schema: { type: :integer }, required: false
      parameter name: :performed_at_from, in: :query, schema: { type: :string }, required: false
      parameter name: :performed_at_to, in: :query, schema: { type: :string }, required: false
      parameter name: :chore_name, in: :query, schema: { type: :string }, required: false
      parameter name: :page, in: :query, schema: { type: :integer }, required: false
      parameter name: :limit, in: :query, schema: { type: :integer }, required: false

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
          data = json['data']
          expect(data.map { |item| item['id'] }).to contain_exactly(matched.id)
          expect(json['meta']['total_count']).to eq(1)
        end
      end

      response '200', 'paginated first page' do
        let!(:user) { create(:user) }
        let!(:chore) { create(:chore) }
        let!(:records) do
          base = Time.zone.parse('2026-03-01 12:00:00')
          5.times.map do |i|
            create(:chore_record, chore: chore, performer: user, creator: user, performed_at: base + i.seconds)
          end
        end
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:page) { 1 }
        let(:limit) { 2 }

        let(:ordered_ids) do
          records.sort_by { |r| [ -r.performed_at.to_f, -r.id ] }.map(&:id)
        end

        run_test! do |response|
          expect(json['data'].size).to eq(2)
          expect(json['data'].map { |row| row['id'] }).to eq(ordered_ids.first(2))
          expect(json['meta']).to include(
            'total_count' => 5,
            'total_pages' => 3,
            'current_page' => 1,
            'next_page' => 2
          )
        end
      end

      response '200', 'paginated last page' do
        let!(:user) { create(:user) }
        let!(:chore) { create(:chore) }
        let!(:records) do
          base = Time.zone.parse('2026-03-01 12:00:00')
          5.times.map do |i|
            create(:chore_record, chore: chore, performer: user, creator: user, performed_at: base + i.seconds)
          end
        end
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:page) { 3 }
        let(:limit) { 2 }

        let(:ordered_ids) do
          records.sort_by { |r| [ -r.performed_at.to_f, -r.id ] }.map(&:id)
        end

        run_test! do |response|
          expect(json['data'].map { |row| row['id'] }).to eq([ ordered_ids[4] ])
          expect(json['meta']).to include(
            'current_page' => 3,
            'next_page' => nil,
            'total_count' => 5
          )
        end
      end
    end
  end

  path '/api/v1/chore_records/{id}' do
    get 'Show chore record' do
      tags 'ChoreRecords'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :integer }

      response '200', 'ok' do
        let!(:user) { create(:user, name: '创建者') }
        let!(:chore_record) { create(:chore_record, creator: user, performer: user) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:id) { chore_record.id }

        run_test! do |response|
          expect(json['data']['id']).to eq(chore_record.id)
        end
      end
    end

    put 'Update chore record' do
      tags 'ChoreRecords'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :integer }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          points: { type: :number }
        }
      }

      response '200', 'updated' do
        let!(:user) { create(:user, name: '创建者') }
        let!(:chore_record) { create(:chore_record, creator: user, performer: user, points: 1.0) }
        let(:Authorization) { "Bearer #{Auth::TokenIssuer.issue_pair(user: user)[:access_token]}" }
        let(:id) { chore_record.id }
        let(:payload) { { points: 2.5 } }

        run_test! do |response|
          expect(json['data']['points']).to eq("2.5")
        end
      end
    end

    delete 'Delete chore record' do
      tags 'ChoreRecords'
      security [ { bearerAuth: [] } ]
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
