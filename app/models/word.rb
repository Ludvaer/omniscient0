class Word < ApplicationRecord
  belongs_to :dialect
  has_many :translations
end
