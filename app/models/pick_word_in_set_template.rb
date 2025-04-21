class PickWordInSetTemplate < ApplicationRecord
    belongs_to :user
    belongs_to :direction, :class_name => 'PickWordInSetDirection'
    validates :direction, uniqueness: { scope: :user }

    def self.find_or_init(direction, user)
      puts "starting PickWordInSetTemplate find_or_init #{direction&.inspect} #{user&.inspect}"
      if direction.id && user.id
        template = PickWordInSetTemplate.find_or_initialize_by(direction_id: direction.id, user_id: user.id)
      end
      return template if template
      template = PickWordInSetTemplate.new(user: user, direction: direction)
      return template
    end
end
