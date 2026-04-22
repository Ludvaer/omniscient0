require 'nokogiri'
require 'core_ext/string/kana_extensions'
words_to_track = [93410, 31444, 7327]

Word.eager_load(:translations)\
  .where(dialect_id: Dialect.japanese.id)\
  # .order(word: :id, "CHAR_LENGTH(translations.translation)")\
  .all.each do |word|
    readings = word.translations.to_a.filter{|t|t.translation_dialect_id == Dialect.kana.id}
    filtered_readings = []
    puts "#{word.spelling} exists" if words_to_track.include?(word.id)
    readings.group_by(&:translation).each do |text, ts|
      puts "#{word.spelling}: (#{text}): #{ts.map{|t|t.translation}} #{ts.length <=1}" if words_to_track.include?(word.id)
      puts "delete multiple same kana #{word.spelling} -> #{ts.first.translation}"  if ts.length > 1
      ts.drop(1).each{|t|t.delete}
      filtered_readings.append(ts[0])
    end
    readings = filtered_readings

    alts = word.translations.to_a.filter{|t|t.translation_dialect_id == Dialect.japanese.id}
    alts_as_readings = alts.map(&:translation).filter{|a|a.kana_with_symbol?}.map{|a|a.safe_hiragana}
    alts_as_readings.append(word.spelling.safe_hiragana) if word.spelling and word.spelling.kana_with_symbol?

    # find reading
    translations = readings.sort_by{|t|t.translation.length}
    if  translations.blank? and not alts_as_readings.blank?
      translations = readings.map{|r| \
        Translation.find_or_create_by!(\
          word_id: word.id,\
          translation_dialect_id:Dialect.kana.id,\
          translation: r,\
          rank: word.rank,\
          priority: word.rank ,\
        )}
    end
    if translations.blank?
      puts "missing reading #{word.spelling}"
      TemplateWordProgress.where(word_id: word.id).each{|twp|twp.delete}
      word.translations.each{|t|t.delete}
      word.delete
    else
      puts "existing reading confirmed #{word.spelling} -> #{translations.map(&:translation)}" if words_to_track.include?(word.id)
    end

    alts.group_by(&:translation).each do |text, ts|
      puts "#{word.spelling}: (#{text}): #{ts.map{|t|t.translation}} #{ts.length <=1}" if words_to_track.include?(word.id)
      puts "delete multiple same alts #{word.spelling} -> #{ts.first.translation}"  if ts.length > 1
      ts.drop(1).each{|t|t.delete}
      filtered_readings.append(ts[0])
      t = ts.first
      if t.translation.contains_kanji? and !word.spelling.contains_kanji?
        "swapping #{word.spelling} <-> #{t.translation}"
        spelling = word.spelling
        word.update!(spelling: t.translation)
        t.update!(translation: spelling)
      end
    end

    translations.each do |translation|
      puts "unkana #{translation&.translation} for #{word.spelling}" unless translation&.translation&.kana_with_symbol?
    end
end
