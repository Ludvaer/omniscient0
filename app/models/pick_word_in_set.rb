class PickWordInSet < ApplicationRecord
  belongs_to :translation_set
  belongs_to :user
  belongs_to :correct, :class_name => 'Translation'
  belongs_to :picked, :class_name => 'Translation', optional: true
  attr_readonly :correct_id
  attr_readonly :version
  attr_readonly :translation_set_id
  attr_readonly :user_id
end
