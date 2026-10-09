# frozen_string_literal: true

class Chore < ApplicationRecord
  has_many :chore_records, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  before_save :rebuild_search_vector!, if: :search_source_changed?

  scope :active, -> { where(active: true) }

  # Full-text search on precomputed `search_vector` (simple + jieba tokens in `search_tokens`).
  # match: :any — any token matches; :all — plainto_tsquery ANDs all tokens.
  # relevance: true — ORDER BY ts_rank (higher = more matching lexemes in `simple` config).
  scope :search_fulltext, lambda { |text, match: :any, relevance: true|
    tokens = klass.segment_text(text)
    relation = self
    return relation.none if tokens.empty?

    ranked = lambda do |rel, rank_tsquery_sql, rank_binds|
      next rel unless relevance

      rel.order(Arel.sql(klass.sanitize_sql_array([ "ts_rank(search_vector, #{rank_tsquery_sql}) DESC", *rank_binds ])))
    end

    if match == :all
      q = tokens.join(' ')
      rel = relation.where('search_vector @@ plainto_tsquery(\'simple\', ?)', q)
      ranked.call(rel, 'plainto_tsquery(\'simple\', ?)', [ q ])
    else
      first, *rest = tokens.map { |t| relation.where('search_vector @@ plainto_tsquery(\'simple\', ?)', t) }
      combined = rest.reduce(first) { |acc, scope| acc.or(scope) }
      parts = tokens.map { 'plainto_tsquery(\'simple\', ?)' }.join(' || ')
      ranked.call(combined, parts, tokens)
    end
  }

  def self.segment_text(text)
    raw = text.to_s.strip
    return [] if raw.blank?

    segment = Rails.application.config.x.jieba_segment
    return raw.split(/\s+/).map(&:strip).reject(&:blank?).uniq if segment.nil?

    begin
      cut = segment.cut(raw)
      pieces =
        case cut
        when Array then cut
        else cut.to_s.split(/\s+/)
        end
    rescue LoadError, StandardError
      pieces = raw.split(/\s+/)
    end

    pieces.map(&:strip).reject(&:blank?).uniq
  end

  def self.to_tsvector_sql(token_string)
    return nil if token_string.blank?

    connection.select_value(
      sanitize_sql_array([ 'SELECT to_tsvector(\'simple\', ?::text)', token_string ])
    )
  end

  def rebuild_search_vector!
    combined = [ name, search_keywords ].compact.join(' ')
    self.search_tokens = self.class.segment_text(combined).join(' ')
    self.search_vector =
      if search_tokens.blank?
        nil
      else
        self.class.to_tsvector_sql(search_tokens)
      end
  end

  private

  def search_source_changed?
    new_record? || will_save_change_to_name? || will_save_change_to_search_keywords?
  end
end
