class Translation < ApplicationRecord
  belongs_to :word
  belongs_to :user
  has_and_belongs_to_many :translation_sets
  has_many :user_translation_learn_progresses
end
