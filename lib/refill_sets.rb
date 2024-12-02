i = 0
TranslationSet.joins(:translations, translations: :word).includes(:translations, translations: :word).each do |translation_set|
  translations = translation_set.translations
  existing_translations_ids = translations.map{|t| t.id}.to_set
  source_language_id = Dialect.find_by(id: translations.first.word.dialect_id).language_id
  target_language_id = Dialect.find_by(id: translations.first.translation_dialect_id).language_id
  languages = [source_language_id, target_language_id]
  dialect_ids = Dialect.where(language_id:languages).pluck(:id)
  word_ids = translations.map{|t|t.word.id}
  all_relevant_translations = Translation.joins(:word).where(word:{id: word_ids}, translation_dialect_id:dialect_ids)
  missing_translations_ids = all_relevant_translations.pluck(:id).filter{|id| existing_translations_ids.exclude?(id)}

  values = missing_translations_ids.map { |t_id| "(#{translation_set.id}, #{t_id})" }.join(", ")
  if(values.length > 0)
    sql = "INSERT INTO translation_sets_translations (translation_set_id, translation_id) VALUES #{values}"
    ActiveRecord::Base.connection.execute(sql)
  end
  if i % 100 == 0
    puts "languages #{languages}"
    puts "dialect_ids #{dialect_ids}"
    puts "added #{values.length} to #{existing_translations_ids.length} existing set"
  end
  i += 1
end
