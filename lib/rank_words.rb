words = Word.eager_load(:translations).where(translations: {translation_dialect_id:[Dialect.english.id]}).to_a
words.sort_by!{|w| w.translations.min_by{|t| t.rank}.rank*10 +
  w.translations.max_by{|t| t.rank}.rank }

words.each_with_index do |word, i|
  word.update!(rank: i + 1)
end
