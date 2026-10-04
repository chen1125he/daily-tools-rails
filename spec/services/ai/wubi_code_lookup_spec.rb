# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::WubiCodeLookup do
  def ai_response(content)
    { 'choices' => [ { 'message' => { 'content' => content } } ] }
  end

  it 'returns lowercase 86 wubi code and roots' do
    allow(AliyunAi).to receive(:chat).and_return(
      ai_response('{"character":"春","wubi_code":"DWU","wubi_roots":["三","人","日"]}')
    )

    expect(described_class.call(character: '春')).to eq(
      wubi_code: 'dwu',
      wubi_roots: %w[三 人 日]
    )
    expect(AliyunAi).to have_received(:chat).with(hash_including(model: Setting.ai_wubi_lookup_model))
  end

  it 'parses wubi payload from mixed text' do
    allow(AliyunAi).to receive(:chat).and_return(
      ai_response('编码如下 {"wubi_code":"ggll","wubi_roots":"工工田田"}')
    )

    expect(described_class.call(character: '一')).to eq(
      wubi_code: 'ggll',
      wubi_roots: %w[工 工 田 田]
    )
  end

  it 'raises when character is invalid' do
    expect { described_class.call(character: '春晓') }.to raise_error(Ai::WubiCodeLookup::ParseError, /单个汉字/)
    expect { described_class.call(character: 'A') }.to raise_error(Ai::WubiCodeLookup::ParseError, /单个汉字/)
  end

  it 'raises when AI returns invalid code' do
    allow(AliyunAi).to receive(:chat).and_return(ai_response('{"wubi_code":"dwuuu","wubi_roots":["三"]}'))

    expect { described_class.call(character: '春') }.to raise_error(Ai::WubiCodeLookup::ParseError, /有效五笔编码/)
  end

  it 'raises when roots length does not match code' do
    allow(AliyunAi).to receive(:chat).and_return(ai_response('{"wubi_code":"dwu","wubi_roots":["三"]}'))

    expect { described_class.call(character: '春') }.to raise_error(Ai::WubiCodeLookup::ParseError, /有效五笔字根/)
  end
end
