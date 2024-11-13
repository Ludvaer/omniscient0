class TranslationSet < ApplicationRecord
    has_and_belongs_to_many :translations
    has_many :pick_word_in_sets
    def self.contained_associations
      [:translations]
    end
    # Mark as a container
    def self.is_container
      true
    end
end
