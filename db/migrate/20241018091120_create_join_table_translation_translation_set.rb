class CreateJoinTableTranslationTranslationSet < ActiveRecord::Migration[7.0]
  def change
    create_join_table :translations, :translation_sets do |t|
      # t.index [:translation_id, :translation_set_id]
      # t.index [:translation_set_id, :translation_id]
    end
  end
end
