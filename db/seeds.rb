# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
require 'csv'

csv_text = File.read(Rails.root.join('db', 'seeds', 'users.csv'))
csv_text.gsub! '"', ''
csv_text.gsub! ' ', ''
csv = CSV.parse(csv_text, :headers => true, :encoding => 'UTF-8', :col_sep => '	')
csv.each do |row|
  unless User.where(name:row['name']).exists?
      puts "regenerate user #{row['name']}"
      user = User.new
      user.name = row['name']
      user.email = row['email']
      user.downame = row['downame']
      user.activated = row['activated']
      user.password_digest = row['password_digest']
      user.save
  end
end
puts 'users are finished'
User.all.each do |user|
  unless user.activated
    puts "activate user #{user.name}"
    user.update_attribute(:activated, true)
  end
end
puts 'users are activated'

csv_text = File.read(Rails.root.join('db', 'seeds', 'languages.csv'))
csv = CSV.parse(csv_text, :headers => true, :encoding => 'ISO-8859-1')
csv.each do |row|
  unless Language.where(name:row['name']).exists?
      language = Language.new
      language.name = row['name']
      language.save
  end
  unless Dialect.where(name:row['name']).exists?
      language = Language.find_by(name:row['name'])
      dialect = Dialect.new
      dialect.name = row['name']
      dialect.language_id = language.id
      dialect.save
  end
end
puts 'languages are finished'

csv_text = File.read(Rails.root.join('db', 'seeds', 'dialects.csv'))
csv = CSV.parse(csv_text, :headers => true, :encoding => 'ISO-8859-1')
csv.each do |row|
  language = Language.find_by(name:row['language'])
  unless Dialect.where(name:row['dialect']).exists?
      dialect = Dialect.new
      dialect.name = row['dialect']
      dialect.language_id = language.id
      dialect.save
  end
end
puts 'dialects are finished'

japanese_dialect_id =  Dialect.find_by(name:'japanese').id
kanji_dialect_id =  Dialect.find_by(name:'kanji').id
kana_dialect_id =  Dialect.find_by(name:'kana').id
english_dialect_id =  Dialect.find_by(name:'english').id
russian_dialect_id =  Dialect.find_by(name:'russian').id
deleted_without_kana = 0
kept_with_kana = 0
deleted_jap_duplicated = 0
Word.where(dialect_id: japanese_dialect_id).each do |word|
  kana = word.translations.where(translation_dialect_id:kana_dialect_id)&.first&.translation.to_s
  if kana.blank?
    word.delete
    deleted_without_kana = deleted_without_kana + 1
    next
  else
    kept_with_kana = kept_with_kana +1
  end
end

existing_jap_words = Word
  .where(dialect_id:[japanese_dialect_id,kanji_dialect_id])
  .group_by{|w| w.spelling + "|" + w.translations.where(translation_dialect_id:kana_dialect_id)&.first&.translation.to_s }
existing_jap_words.values.each do |same_words|
  same_words.drop(1).each do |sw|
    sw.delete
    deleted_jap_duplicated = deleted_jap_duplicated + 1
  end
end

puts "deleted #{deleted_without_kana} jap word without kana and #{deleted_jap_duplicated} duplicates"
puts "#{kept_with_kana} jap words and total #{existing_jap_words.size} diffrent keys ar kept"

kana_tranlations = Translation.where(translation_dialect_id: kana_dialect_id)
kana_tranlations.each do |kt|
  if kt.translation != kt.translation.downcase.hiragana
    puts "[#{kt.translation}] != [#{kt.translation.downcase.hiragana}]"
    kt.translation = kt.translation.downcase.hiragana
    kt.save
  end
end
deleted_kana_duplicated = 0
kana_tranlations.group_by{|kt| kt.word.spelling + '|' + kt.translation}.values.each do |same_kanas|
  same_kanas.drop(1).each do |sk|
    sk.delete
    deleted_kana_duplicated = deleted_kana_duplicated + 1
  end
end
puts "#{deleted_kana_duplicated} tranlations are deleted as duplicated kana"

def parse_csv(provider, file_path, dialect_from)
  japanese_dialect_id =  Dialect.find_by(name:'japanese').id
  kanji_dialect_id =  Dialect.find_by(name:'kanji').id
  kana_dialect_id =  Dialect.find_by(name:'kana').id
  english_dialect_id =  Dialect.find_by(name:'english').id
  russian_dialect_id =  Dialect.find_by(name:'russian').id
  dialect_from_id = dialect_from.id
  dialect_from_name = dialect_from.name
  dialect_from_column_name = dialect_from.name.capitalize
  csv_text = File.read(file_path)
  csv = CSV.parse(csv_text, :headers => true, :encoding => 'UTF-8', :col_sep => '|')
  user = User.find_by(name: provider)
  existing_translations = Translation.joins(:word)
    .where('word.dialect_id':dialect_from_id, user_id: user.id)
    .group_by{|t| t.word.spelling + "|" + t.word.translations.where(translation_dialect_id:kana_dialect_id)&.first&.translation.to_s }
  existing_jap_words = Word
    .where(dialect_id:dialect_from_id)
    .group_by{|w| w.spelling + "|" + w.translations.where(translation_dialect_id:kana_dialect_id)&.first&.translation.to_s }

  overriden_translations = {"0":false}
  existing_translations.keys.each do |k|
    overriden_translations[k] = false
  end

  puts "start parsing csv for #{provider} with existing seed #{existing_translations.size} translations "
  #  puts "start parsing csv for #{provider} with existing seed translations #{existing_translations.take(100)}"
  counter = 0
  counter_deleted = 0
  counter_confirmed = 0
  counter_updated = 0
  counter_saved = 0
  counter_word = 0
  skipped_same_kana = 0
  csv.each do |row|
    counter = counter + 1
    if counter%200 == 0
      puts "#{counter} progress"
    end
    japanese = row[dialect_from_column_name].split(/;/)[0]
    romaji = row['Romaji']&.split(/;/)&.first
    english = row['English'].to_s
    russian = row['Russian'].to_s
    utility = row['Utility'].to_i
    use = row['Use'].to_i
    priority = utility * 100
    if dialect_from_name == "kanji"
      priority = use + utility * 100
      if use == 0
        priority = utility * 100 + 9999
      end
    else
      chars = japanese.each_char.map{|ch| ch}
      translations_for_kanji = Translation.joins(:word)
        .where(word:{dialect_id:kanji_dialect_id, spelling:chars})
      if translations_for_kanji.empty?
        if utility.nil? or  utility <= 0 or utility >= 10
          priority = 9999 + 100 * 100
        else
          priority = utility * 200
        end
      else
        if utility.nil? or utility <= 0 or utility >= 10 #i shoud think about if utility has any wight compa
          priority = 20 + translations_for_kanji.map{|k| k&.priority.to_i}.max
        else
          priority = utility * 2 + translations_for_kanji.map{|k| k&.priority.to_i}.max
        end
      end
    end
    romaji&.gsub! 'ō', 'ou'
    romaji&.gsub! 'ā', 'aa'
    romaji&.gsub! 'ē', 'ee'
    romaji&.gsub! 'o:', 'ou'
    romaji&.gsub! 'a:', 'aa'
    romaji&.gsub! 'e:', 'ee'
    hiragana = romaji&.downcase&.hiragana.to_s
    #words = Word.where(spelling:japanese, dialect_id:japanese_dialect_id)

    # words = Word.where(spelling:japanese, dialect_id:japanese_dialect_id)
    # key = japanese + "|" + word.translations.where(translation_dialect_id:kana_dialect_id)&.first&.translation.to_s
    key = japanese + "|" + hiragana
    existing_word_translations = existing_translations[key]
    word = nil
    if !existing_word_translations.nil? and existing_word_translations&.size > 0
        word = Word.find_by(id:existing_word_translations[0].word_id)
    end
    if word.nil?
        word = existing_jap_words[key]&.first
    end
    if word.nil?
        word = Word.new
        word.spelling = japanese
        word.dialect_id = dialect_from_id
        word.save
        word = word.reload
        counter_word = counter_word + 1
    end

    array = [[english_dialect_id,english],[russian_dialect_id,russian],[kana_dialect_id,hiragana]]

    if word.spelling.blank?
      next
    end
    # puts "updating key: #{key}"
    array.each do |dialect_id, translation_text|
      if dialect_id.blank? or translation_text.blank?
        next
      end
      translations = existing_word_translations&.select{|ewt| ewt.translation_dialect_id == dialect_id}
      # puts "#{key} for dialct #{dialect_id} has #{translations&.size} translations"
      translation = if !translations&.size.nil? and translations&.size > 0 then translations[0] else nil end
      if translation.nil? and dialect_id == kana_dialect_id
        translation = word.reload.translations.where(translation_dialect_id:dialect_id,translation:translation_text)
        unless translation.nil?
          skipped_same_kana = skipped_same_kana + 1
          next
        end
      end
      if translation.nil?
        translation = Translation.new
      end
      if (translation.translation == translation_text and translation.priority == priority and translation.word_id = word.id) or overriden_translations[key]
        counter_confirmed = counter_confirmed + 1
        # puts "skipping [#{translation.translation}] == [#{translation_text}]"
      else
        if translation.id.nil?
          counter_saved = counter_saved + 1
        else
          counter_updated = counter_updated + 1
        end
        # puts "[#{translation.translation}] != [#{translation_text}] or [#{translation.priority}] != [#{priority}]"
        # puts "#{user.name}: [id:#{translation.id}] #{key} translates to #{Dialect.find_by(id:dialect_id).name} as '#{translation_text}'"
        translation.word_id = word.id
        translation.translation = translation_text
        translation.translation_dialect_id = dialect_id
        translation.user = user
        translation.priority = priority
        translation.save
      end
      translations&.drop(1)&.each do |t|
        counter_deleted = counter_deleted + 1
        puts "REMOVED DUPLICATE [id:#{translation.id}] #{key} translates to #{Dialect.find_by(id:dialect_id).name} as '#{translation_text}'"
        t.delete
      end
    end
    overriden_translations[key] = true
  end
  puts "checked #{counter} rows; #{counter_confirmed} are confirmed;  #{counter_updated} are updated;  new #{counter_saved} are saved"
  puts "#{counter_word} new source words are saved, while #{skipped_same_kana} duplicate creation skipped "
  puts "finished parsing csv for #{provider}"
  existing_translations.keys.each do |k|
    unless overriden_translations[k]
      puts "removing unconfirmed translations with key #{k}"
      existing_translations[k].each{|t| t.delete }
    end
  end
  puts "finished clenaup of unconfirmed translations for #{provider}"
end

kanji_files =
  [
    ["YarxiSeed",Rails.root.join('db', 'seeds', 'yarxi', 'BasicRussianKanji.csv')],
    ["JishopSeed",Rails.root.join('db', 'seeds', 'jishop', 'BasicEnglishKanji.csv')],
  ]
kanji_files.each do |provider,file_path|
  parse_csv(provider,file_path,Dialect.find_by(name:'kanji'))
end
puts "finished seeding kanji"

jap_files =
  [
    ["HirokoStormSeed",Rails.root.join('db', 'seeds', 'japanese_to_english_translations.csv')],
    ["YarxiSeed",Rails.root.join('db', 'seeds', 'yarxi', 'DictionaryRussianKanji.csv')],
    ["YarxiComboSeed",Rails.root.join('db', 'seeds', 'yarxi', 'DictionaryRussianCompound.csv')],
    ["JishopSeed",Rails.root.join('db', 'seeds', 'jishop', 'DictionaryEnglishKanji.csv')],
    ["JishopComboSeed",Rails.root.join('db', 'seeds', 'jishop', 'DictionaryEnglishCompound.csv')]
  ]
jap_files.each do |provider,file_path|
  parse_csv(provider,file_path,Dialect.find_by(name:'japanese'))
end
puts "finished seeding jap words"

counter_deleted = 0
Translation.all.each do |t|
  unless Dialect.where(id: t.translation_dialect_id).exists?
    counter_deleted = counter_deleted + 1
    puts "REMOVED obsolete [id:#{t.id}] #{t.word.spelling} translates to lost dialect as '#{t.translation}'"
    t.delete
  end
  unless Word.where(id: t.word_id).exists?
    counter_deleted = counter_deleted + 1
    puts "REMOVED obsolete [id:#{t.id}] lost word translates as '#{t.translation}'"
    t.delete
  end
end
puts "finished clenaup of #{counter_deleted} obsolete translations for db"

TranslationSet.all.each do |set|
  set.translations.each do |t|
    if t.nil? or Translation.find_by(id:t.id).nil?
      puts "REMOVED obsolete set [id:#{set.id}] with lost translation"
      set.delete
      break
    end
  end
end
puts "finished clenaup of obsolete TranslationSet"
PickWordInSet.all.each do |pick|
  if TranslationSet.find_by(id:pick.translation_set_id).nil?
    puts "REMOVED obsolete pick [id:#{pick.id}] sith lost translation set"
    pick.delete
  end
end
puts "finished clenaup of obsolete PickWordInSet"
