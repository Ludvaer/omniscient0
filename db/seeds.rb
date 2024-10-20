# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
require 'csv'

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

csv_text = File.read(Rails.root.join('db', 'seeds', 'japanese_to_english_translations.csv'))
csv = CSV.parse(csv_text, :headers => true, :encoding => 'UTF-8', :col_sep => '|')
japanese_dialect_id =  Dialect.find_by(name:'japanese').id
kana_dialect_id =  Dialect.find_by(name:'kana').id
english_dialect_id =  Dialect.find_by(name:'english').id
russian_dialect_id =  Dialect.find_by(name:'russian').id
csv.each do |row|
  japanese = row['japanese'].split(/;/)[0]
  romaji = row['romaji'].split(/;/)[0]
  english = row['english']
  russian = row['russian']
  hiragana = romaji.hiragana
  unless Word.where(spelling:japanese, dialect_id:japanese_dialect_id).exists?
      word = Word.new
      word.spelling = japanese
      word.dialect_id = japanese_dialect_id
      word.save
  end
  word_id = Word.find_by(spelling:japanese,dialect_id:japanese_dialect_id).id
  array = [[english_dialect_id,english],[russian_dialect_id,russian],[kana_dialect_id,hiragana]]
  word = Word.find_by(spelling:japanese, dialect_id:japanese_dialect_id)
  array.each do |dialect_id, translation_text|
    translations = Translation.where(word_id:word_id, translation_dialect_id:dialect_id)
    translation = if translations.exists? then translations[0] else Translation.new end
    unless translation.translation == translation_text
      puts "[#{translation.translation}] != [#{translation_text}]"
      puts "[id:#{translation.id}] #{word.spelling} translates to #{Dialect.find_by(id:dialect_id).name} as '#{translation_text}'"
      translation.word_id = word_id
      translation.translation = translation_text
      translation.translation_dialect_id = dialect_id
      translation.save
    end
    translations.drop(1).each do |t|
      puts "REMOVED DUPLICATE [id:#{translation.id}] #{word.spelling} translates to #{Dialect.find_by(id:dialect_id).name} as '#{translation_text}'"
      t.delete
    end
  end
  Translation.all.each do |t|
    unless Dialect.where(id: t.translation_dialect_id).exists?
      puts "REMOVED DUPLICATE [id:#{t.id}] #{word.spelling} translates to lost dialect as '#{t.translation}'"
      t.delete
    end
  end
end
