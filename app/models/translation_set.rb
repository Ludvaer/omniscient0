class TranslationSet < ApplicationRecord
    has_and_belongs_to_many :translations
    has_many :pick_word_in_sets
end
