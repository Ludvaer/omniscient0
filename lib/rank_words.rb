words = Word.eager_load(:translations).where(translations: {translation_dialect_id:[Dialect.english.id]}).to_a
users1 = [User.yarxi_seed,User.yarxi_combo_seed,User.jishop_seed,User.jishop_combo_seed].map(&:id)
users2 = [User.jmdict_parser].map(&:id)
max_priority = 100000

words.sort_by!{|w| (w.translations.filter{|t|users1.include?(t.user_id)}.min_by{|t| t.rank}&.rank || max_priority) + \
    2 * (w.translations.filter{|t|users2.include?(t.user_id)}.min_by{|t| t.rank}&.rank || max_priority ) \
  + 3 * (w.translations.min_by{|t| t.rank}&.rank || max_priority)}

words.each_with_index do |word, i|
  word.update!(rank: i + 1)
end
