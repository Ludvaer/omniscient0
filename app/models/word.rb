class Word < ApplicationRecord
  belongs_to :dialect
  has_many :translations

  def self.max_rank(target_dialect)
    puts('word max_rank called')
    Rails.cache.fetch("word/max_rank?target=" + target_dialect.name, expires_in: nil ) do
          Word.where(dialect: target_dialect).pluck(:rank).max
    end
  end

  #jap words are defined by key with jap word and it's readings
  #this returns dictionary by such key with | deliminator and
  #and words with preloaded translations as value
  def self.existing_japanese_by_key
    Word.joins(:translations).includes(:translations)
      .where(dialect_id: Dialect.japanese.id)
      .group_by{|w| (w.spelling or '_') + "|" + w.translations.where(translation_dialect_id: Dialect.kana.id)&.pluck(:translation)
        .map{|t|t.split(' ')[0]}.uniq.sort.join('|')&.to_s}
  end
end
