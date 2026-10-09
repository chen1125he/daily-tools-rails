# frozen_string_literal: true

# Load cppjieba once per process at boot (dict I/O + noisy logs happen only here).
Rails.application.config.x.jieba_segment =
  begin
    require 'jieba_rb'
    JiebaRb::Segment.new
  rescue LoadError, StandardError => e
    Rails.logger&.warn("[jieba] init failed, falling back to whitespace tokenization: #{e.message}")
    nil
  end
