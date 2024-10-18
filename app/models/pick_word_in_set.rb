class PickWordInSet < ApplicationRecord
  belongs_to :translation_set
  attr_readonly :correct_id
  attr_readonly :version
  attr_readonly :translation_set_id
  attr_readonly :user_id
end
