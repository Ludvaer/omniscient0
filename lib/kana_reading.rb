require 'core_ext/string/kana_extensions'

Word.eager_load(:translations)\
  .where(dialect_id: Dialect.japanese.id)\
  # .order(word: :id, "CHAR_LENGTH(translations.translation)")\
  .all.each do |word|
    readings = word.translations.to_a.filter{|t|t.translation_dialect_id == Dialect.kana.id}
    filtered_readings = []
    readings.group_by(&:translation).each do |text, ts|
      # puts "#{text} #{ts.map{|t|t.translation}} #{ts.length <=1}"
      ts.drop(1).each{|t|t.delete}
      filtered_readings.append(ts[0])
      #puts "delete multiple same kana #{word.spelling} -> #{ts.first.translation}"
    end
    readings = filtered_readings

    # find reading
    translation = readings.sort_by{|t|t.translation.length}.first
    translation = Translation.find_or_create_by!(\
        word_id: word.id,\
        translation_dialect_id:Dialect.kana.id,\
        translation: word.spelling.safe_hiragana,\
        rank: word.rank,\
        priority: word.rank ,\
      ) if word.spelling and word.spelling.kana_with_symbol? and not translation
    unless translation
      puts "missing reading #{word.spelling}"
      TemplateWordProgress.where(word_id: word.id).each{|twp|twp.delete}
      word.translations.each{|t|t.delete}
      word.delete
    end
    puts "unkana #{translation&.translation} for #{word.spelling}" unless translation&.translation&.kana_with_symbol?

end
