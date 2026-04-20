#this script removes words with suffixes and moves their translations to original words
counter = 0
Word.joins(:translations).includes(:translations)
    .where(dialect_id: Dialect.japanese.id).each do |word|

  if not word.spelling
    word.translations.each{|t|t.delete}
    word.delete
    next
  end
  word.translations.each do |t|
    if t.translation_dialect_id == Dialect.kana.id and t.translation.include?(' ')
      puts "remmove #{t.translation}"
      counter += 1
      t.delete
      next
    end
    if t.translation_dialect_id == Dialect.kana.id and not t.translation.kana_with_symbol?
      ttranslation = t.translation
      t.update!(translation: t.translation.safe_hiragana)
      puts "update #{ttranslation} #{t.translation}"
      counter += 1
      next
    end
  end
  if not word.translations.any?{|t|t.translation_dialect_id == Dialect.kana.id}
    puts "remmove #{word.spelling}"
    TemplateWordProgress.where(word_id: word.id).each{|twp|twp.delete}
    word.translations.each{|t|t.delete}
    word.delete
    counter += 1
  end
  if not word.spelling.include?(' ')
    next
  end
  counter += 1

  word_parts = word.spelling.split(' ', 2)
  base = word_parts[0]
  suffix = word_parts[1]
  base_word = Word.find_or_create_by!(
    spelling: base,
    dialect_id: word.dialect_id
  )
  # if base_word.user_id == 0
  #   base_word.update!(user_id: word.user_id)
  # end
  puts "#{base} + ~#{suffix} -> #{base_word.spelling} "
  word.translations.each do |translation|
    translation.update!(suffix: suffix, word_id: base_word.id)
    puts "[#{translation.user_id}]  ~#{suffix}: #{translation.translation} "
  end
  TemplateWordProgress.where(word_id: word.id).each{|twp|twp.delete}
  word.delete
  puts counter
end
