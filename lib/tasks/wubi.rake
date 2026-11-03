# frozen_string_literal: true

require 'csv'

namespace :wubi do
  desc '解析 lib/wubi_pinyin_unicode_data.txt，导出字与五笔码到同目录 CSV'
  task export_unicode_data: :environment do
    source = Rails.root.join('lib/wubi_pinyin_unicode_data.txt')
    target = Rails.root.join('lib/wubi_pinyin_unicode_data.csv')

    count = 0
    CSV.open(target, 'w') do |csv|
      csv << %w[character wubi_code]
      File.foreach(source, encoding: 'UTF-8') do |line|
        line = line.strip
        next if line.empty?

        parts = line.split('|')
        next if parts.size < 4

        csv << [parts[0], parts[3].split(',').last]
        count += 1
        pp [count, parts[0], parts[3]]
      end
    end

    puts "已导出 #{count} 行到 #{target}"
  end

  desc '从 lib/wubi_pinyin_unicode_data.csv 导入到 typing_words'
  task import_unicode_data: :environment do
    source = Rails.root.join('lib/wubi_pinyin_unicode_data.csv')
    raise "找不到文件: #{source}" unless source.exist?

    now = Time.current
    batch = []
    imported = 0
    skipped = 0
    batch_size = 1000

    flush = lambda do
      next if batch.empty?

      TypingWord.upsert_all(
        batch,
        unique_by: :character,
        update_only: %i[wubi_code]
      )
      imported += batch.size
      batch.clear
    end

    CSV.foreach(source, headers: true, encoding: 'UTF-8') do |row|
      character = row['character'].to_s
      wubi_code = row['wubi_code'].to_s.strip.downcase

      if character.length != 1 || !wubi_code.match?(/\A[a-z]{1,4}\z/)
        skipped += 1
        next
      end

      batch << {
        character: character,
        wubi_code: wubi_code,
        created_at: now,
        updated_at: now
      }
      flush.call if batch.size >= batch_size
    end
    flush.call

    puts "已导入/更新 #{imported} 行，跳过 #{skipped} 行"
  end
end

