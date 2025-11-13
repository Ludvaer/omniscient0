class Word < ApplicationRecord
  belongs_to :dialect
  has_many :translations

  def self.max_rank(target_dialect)
    puts('word max_rank called')
    Rails.cache.fetch("word/max_rank?target=" + target_dialect.name, expires_in: nil ) do
          Word.where(dialect: target_dialect).pluck(:rank).max
    end
  end

  def existing_japanese_by_key
    Word.joins(:translations).includes(:translations)
      .where(dialect_id: Dialect.japanse.id)
      .group_by{|w| w.spelling + "|" + w.translations.where(translation_dialect_id: Dialect.kana.id)&.pluck(:translation)&.join('|')&.to_s}
  end
end
