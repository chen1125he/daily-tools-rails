# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::WubiCodeLookup do
  def ai_response(content)
    { 'choices' => [ { 'message' => { 'content' => content } } ] }
  end

  it 'returns lowercase 86 wubi code' do
    allow(AliyunAi).to receive(:chat).and_return(ai_response('{"character":"春","wubi_code":"DWU"}'))

    expect(described_class.call(character: '春')).to eq('dwu')
    expect(AliyunAi).to have_received(:chat).with(hash_including(model: Setting.ai_wubi_lookup_model))
  end

  it 'parses wubi code from mixed text' do
    allow(AliyunAi).to receive(:chat).and_return(ai_response('编码如下 {"wubi_code":"aaaa"}'))

    expect(described_class.call(character: '一')).to eq('aaaa')
  end

  it 'raises when character is invalid' do
    expect { described_class.call(character: '春晓') }.to raise_error(Ai::WubiCodeLookup::ParseError, /单个汉字/)
    expect { described_class.call(character: 'A') }.to raise_error(Ai::WubiCodeLookup::ParseError, /单个汉字/)
  end

  it 'raises when AI returns invalid code' do
    allow(AliyunAi).to receive(:chat).and_return(ai_response('{"wubi_code":"dwuuu"}'))

    expect { described_class.call(character: '春') }.to raise_error(Ai::WubiCodeLookup::ParseError, /有效五笔编码/)
  end
end
