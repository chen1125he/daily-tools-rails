# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TypingWordWubiLookupJob, type: :job do
  include ActiveJob::TestHelper

  after { clear_enqueued_jobs }

  it 'enqueues when a typing word is created without wubi_code' do
    word = TypingWord.create!(character: '春')

    expect(described_class).to have_been_enqueued.with(word.id)
  end

  it 'does not enqueue when wubi_code is already present' do
    TypingWord.create!(character: '春', wubi_code: 'dwu')

    expect(described_class).not_to have_been_enqueued
  end

  it 'writes wubi_code from AI' do
    word = TypingWord.create!(character: '春')
    allow(Ai::WubiCodeLookup).to receive(:call).with(character: '春').and_return('dwu')

    described_class.perform_now(word.id)

    expect(word.reload.wubi_code).to eq('dwu')
  end

  it 'skips lookup when wubi_code already exists' do
    word = TypingWord.create!(character: '春', wubi_code: 'dwu')
    allow(Ai::WubiCodeLookup).to receive(:call)

    described_class.perform_now(word.id)

    expect(Ai::WubiCodeLookup).not_to have_received(:call)
    expect(word.reload.wubi_code).to eq('dwu')
  end
end
