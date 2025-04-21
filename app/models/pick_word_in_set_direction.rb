class PickWordInSetDirection < ApplicationRecord
    belongs_to :target_dialect, :class_name => 'Dialect'
    belongs_to :option_dialect, :class_name => 'Dialect'
    has_and_belongs_to_many :display_dialects,  class_name: 'Dialect',  join_table: 'dialects_pick_directions'
    after_save :deduplicate  # avoiding potentioanl troubles for checking uniqueness considering has_and_belongs_to_many

    def self.find_or_init(target_dialect,display_dialects,option_dialect)
      direction = PickWordInSetDirection.find_all(target_dialect,display_dialects,option_dialect).first
      if direction
        PickWordInSetDirection.joins(:display_dialects).includes(:display_dialects).find_by(id: direction.id)
        return direction
      end
      PickWordInSetDirection.new(
          target_dialect: target_dialect,
          option_dialect: option_dialect,
          display_dialects: display_dialects)
    end

    private

    def deduplicate
      duplicates = PickWordInSetDirection.find_all(target_dialect,display_dialects,option_dialect)\
        .order(:id).to_a
      to_save = duplicates[0]
      duplicates.drop(1).each{|d| d.destroy}
      unless to_save.id == id
        reloaded = to_save
        throw :abort
      end
    end

    def self.find_all(target_dialect,display_dialects,option_dialect)
      display_dialects_ids = display_dialects.map{|d|d.id}.uniq.sort
      target_dialect_id = target_dialect.id
      option_dialect_id = option_dialect.id
      PickWordInSetDirection.joins(:display_dialects)
      .where(
        target_dialect_id: target_dialect_id,
        option_dialect_id: option_dialect_id
      )
      .group('pick_word_in_set_directions.id')
      .having('ARRAY_AGG(dialects_pick_directions.dialect_id ORDER BY dialects_pick_directions.dialect_id) = ARRAY[?]::bigint[]', display_dialects_ids.map(&:to_i).sort)
      #.having('COUNT(1) = ?', display_dialects_ids.size).to_a
    end
end
