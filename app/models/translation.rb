class Translation < ApplicationRecord
  belongs_to :word
  has_and_belongs_to_many :translation_sets
end
