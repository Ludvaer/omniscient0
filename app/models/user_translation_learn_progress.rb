class UserTranslationLearnProgress < ApplicationRecord
    belongs_to :user
    belongs_to :translation
    after_initialize :set_defaults

    def set_defaults
      last_counter ||= 0
      correct ||= 0
      failed ||= 0
    end
end
