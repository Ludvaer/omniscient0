class Word < ApplicationRecord
  belongs_to :dialect
  has_many :translations



  def self.max_rank(target_dialect)
    Rails.cache.fetch("word/max_rank?target=" + target_dialect.name, expires_in: nil ) do
          Word.where(dialect: target_dialect).pluck(:rank).max
    end
  end
end
