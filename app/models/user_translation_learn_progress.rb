class UserTranslationLearnProgress < ApplicationRecord
    belongs_to :user
    belongs_to :translation
end
