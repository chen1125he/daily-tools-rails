# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TypingWordWubiLookupJob, type: :job do
  include ActiveJob::TestHelper

  after { clear_enqueued_jobs }

  let(:ai_result) { { wubi_code: 'dwu', wubi_roots: %w[三 人 日] } }

  it 'enqueues when a typing word is created without wubi data' do
    word = TypingWord.create!(character: '春')

    expect(described_class).to have_been_enqueued.with(word.id)
  end

  it 'enqueues when wubi_code exists but roots are missing' do
    word = TypingWord.create!(character: '春', wubi_code: 'dwu')

    expect(described_class).to have_been_enqueued.with(word.id)
  end

  it 'does not enqueue when wubi data is already complete' do
    TypingWord.create!(character: '春', wubi_code: 'dwu', wubi_roots: %w[三 人 日])

    expect(described_class).not_to have_been_enqueued
  end

  it 'writes wubi_code and roots from AI' do
    word = TypingWord.create!(character: '春')
    allow(Ai::WubiCodeLookup).to receive(:call).with(character: '春').and_return(ai_result)

    described_class.perform_now(word.id)

    word.reload
    expect(word.wubi_code).to eq('dwu')
    expect(word.wubi_roots).to eq(%w[三 人 日])
  end

  it 'fills missing roots when code already exists' do
    word = TypingWord.create!(character: '春', wubi_code: 'dwu')
    allow(Ai::WubiCodeLookup).to receive(:call).with(character: '春').and_return(ai_result)

    described_class.perform_now(word.id)

    expect(word.reload.wubi_roots).to eq(%w[三 人 日])
  end

  it 'skips lookup when wubi data is already complete' do
    word = TypingWord.create!(character: '春', wubi_code: 'dwu', wubi_roots: %w[三 人 日])
    allow(Ai::WubiCodeLookup).to receive(:call)

    described_class.perform_now(word.id)

    expect(Ai::WubiCodeLookup).not_to have_received(:call)
  end
end
