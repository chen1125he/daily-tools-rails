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
end
