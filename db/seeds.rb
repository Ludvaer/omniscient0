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
kana_dialect_id =  Dialect.find_by(name:'kana').id
english_dialect_id =  Dialect.find_by(name:'english').id
russian_dialect_id =  Dialect.find_by(name:'russian').id
kana_tranlations = Translation.where(translation_dialect_id: kana_dialect_id)
kana_tranlations.each do |kt|
  if kt.translation != kt.translation.downcase.hiragana
    puts "[#{kt.translation}] != [#{kt.translation.downcase.hiragana}]"
    kt.translation = kt.translation.downcase.hiragana
    kt.save
  end
end

jap_files =
  [
    ["HirokoStormSeed",Rails.root.join('db', 'seeds', 'japanese_to_english_translations.csv')],
    ["YarxiSeed",Rails.root.join('db', 'seeds', 'yarxi', 'DictionaryRussianKanji.csv')],
    ["YarxiComboSeed",Rails.root.join('db', 'seeds', 'yarxi', 'DictionaryRussianCompound.csv')],
    ["JishopSeed",Rails.root.join('db', 'seeds', 'jishop', 'DictionaryEnglishKanji.csv')],
    ["JishopComboSeed",Rails.root.join('db', 'seeds', 'jishop', 'DictionaryEnglishCompound.csv')]
  ]
lnaguage_dialect_ids = [english_dialect_id, russian_dialect_id]
jap_files.each do |provider,file_path|
  csv_text = File.read(file_path)
  csv = CSV.parse(csv_text, :headers => true, :encoding => 'UTF-8', :col_sep => '|')
  user = User.find_by(name: provider)
  existing_translations = Translation.joins(:word)
    .where('word.dialect_id':japanese_dialect_id, user_id: user.id)
    .group_by{|t| t.word.spelling + "|" + t.word.translations.where(translation_dialect_id:kana_dialect_id)&.first&.translation.to_s }
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
  csv.each do |row|
    counter = counter + 1
    if counter%100 == 0
      puts "checked #{counter} rows; #{counter_confirmed} are confirmed;  #{counter_updated} are updated;  new #{counter_updated} are saved"
    end
    japanese = row['Japanese'].split(/;/)[0]
    romaji = row['Romaji'].split(/;/)[0]
    english = row['English']
    russian = row['Russian']
    romaji.gsub! 'ō', 'ou'
    romaji.gsub! 'ā', 'aa'
    romaji.gsub! 'ē', 'ee'
    romaji.gsub! 'o:', 'ou'
    romaji.gsub! 'a:', 'aa'
    romaji.gsub! 'e:', 'ee'
    hiragana = romaji.downcase.hiragana
    #words = Word.where(spelling:japanese, dialect_id:japanese_dialect_id)

    # words = Word.where(spelling:japanese, dialect_id:japanese_dialect_id)
    # key = japanese + "|" + word.translations.where(translation_dialect_id:kana_dialect_id)&.first&.translation.to_s
    key = japanese + "|" + hiragana
    existing_word_translations = existing_translations[key]
    word = nil
    if !existing_word_translations.nil? and existing_word_translations&.size > 0
        word = existing_word_translations[0].word
    else
        word = Word.new
        word.spelling = japanese
        word.dialect_id = japanese_dialect_id
        word.save
        word = word.reload
    end
    array = [[english_dialect_id,english],[russian_dialect_id,russian],[kana_dialect_id,hiragana]]
    overriden_translations[key] = true
    # puts "updating key: #{key}"
    array.each do |dialect_id, translation_text|
      if dialect_id.nil?
        next
      end
      if translation_text.nil?
        next
      end
      translations = existing_word_translations&.select{|ewt| ewt.translation_dialect_id == dialect_id}
      # puts "#{key} for dialct #{dialect_id} has #{translations&.size} translations"
      translation = if !translations&.size.nil? and translations&.size > 0 then translations[0] else Translation.new end
      if translation.translation == translation_text
        counter_confirmed = counter_confirmed + 1
        # puts "skipping [#{translation.translation}] == [#{translation_text}]"
      else
        if translation.id.nil?
          counter_saved = counter_saved + 1
        else
          counter_updated = counter_updated + 1
        end
        # puts "[#{translation.translation}] != [#{translation_text}]"
        # puts "#{user.name}: [id:#{translation.id}] #{key} translates to #{Dialect.find_by(id:dialect_id).name} as '#{translation_text}'"
        translation.word_id = word.id
        translation.translation = translation_text
        translation.translation_dialect_id = dialect_id
        translation.user = user
        translation.save
      end
      translations&.drop(1)&.each do |t|
        counter_deleted = counter_deleted + 1
        puts "REMOVED DUPLICATE [id:#{translation.id}] #{key} translates to #{Dialect.find_by(id:dialect_id).name} as '#{translation_text}'"
        t.delete
      end
    end
  end
  puts "finished parsing csv for #{provider}"
  existing_translations.keys.each do |k|
    unless overriden_translations[k]
      puts "removing translations with key #{k}"
      existing_translations[k].each{|t| t.delete }
    end
  end
  puts "finished clenaup of unconfirmed translations for #{provider}"
end
Translation.all.each do |t|
  unless Dialect.where(id: t.translation_dialect_id).exists?
    counter_deleted = counter_deleted + 1
    puts "REMOVED DUPLICATE [id:#{t.id}] #{word.spelling} translates to lost dialect as '#{t.translation}'"
    t.delete
  end
end
puts "finished clenaup of obsolete translations for db"
orphaned_translation_sets = TranslationSet
  .left_joins(:translation).group('translation_set.id')
  .having('SUM(CASE WHEN translation.id IS NULL THEN 1 ELSE 0 END) > 0')
puts "REMOVING #{orphaned_translation_sets.size} orphaned translation sets #{orphaned_translation_sets} ..."
# orphaned_word_sets.each(&:destroy)
