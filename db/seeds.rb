# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
require 'csv'
require 'subsets'
require Rails.root.join('lib/core_ext/string/kana_extensions')

#zero translation and zero word are needed for 'do not know' option to be distinguishable from nil / undefined

load Rails.root.join('db', 'seeds', 'users','users.rb')
load Rails.root.join('db', 'seeds', 'languages','languages.rb')

zero_translation = Translation.find_or_create_by!(id:0, word_id:0, user_id:0, translation_dialect_id:0, translation: "")
japanese_dialect_id =  Dialect.japanese.id
kanji_dialect_id =  Dialect.find_by(name:'kanji').id
kana_dialect_id =  Dialect.kana.id
english_dialect_id =  Dialect.find_by(name:'english').id
russian_dialect_id =  Dialect.find_by(name:'russian').id
deleted_without_kana = 0
kept_with_kana = 0
deleted_jap_duplicated = 0

# deleted_kanji_duplicated= 0
# existing_kanji = Word.existing_by_key(Dialect.kanji.id)
# existing_kanji.values.each do |same_words|
#   same_words.drop(1).each do |sw|
#     sw.delete
#     deleted_kanji_duplicated = deleted_jap_duplicated + 1
#   end
# end
# puts  "deleted duplicated kanji #{deleted_kanji_duplicated}"






def parse_csv(provider, file_path, dialect_from)
  tracked_ids = [20265, 6571]
  puts tracked_ids
  word = Word.new
  word_saved = true
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
  user_id = user.id
  existing_jap_words = Word.existing_by_key(dialect_from_id)
  puts "existing_jap_words" + existing_jap_words.keys.take(10).join(', ')
  existing_translations = existing_jap_words.map{|key,words| [key,words.map{|w|w.translations.filter{|t|t.user_id==user.id}}.flatten]}.to_h
  overriden_translations = existing_translations.map{|k,t|t}.flatten.map { |t|[t.id,false]  }.to_h
  saved_words_counter = 0
  puts "start parsing csv for #{provider} with existing #{existing_translations.size} translations "
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
      if !word_saved
        puts "last word errors: #{word.errors.to_json}"
      end
    end
    japanese = row[dialect_from_column_name].split(/;/).map{|x|x.strip}&.map{|t|t.split(' ')[0]}
    romaji = row['Romaji']&.split(/;/)&.map(&:strip)&.filter{|x|not x.blank?}&.map{|t|t.split(' ')[0]}
    w_suffix = row[dialect_from_column_name].include?(' ') \
        ? row[dialect_from_column_name].split(' ', 2)[1]&.gsub('～','')
        : '';
    w_suffix = nil if w_suffix.blank?

    english = [row['English']&.to_s]&.filter{|x|not x.blank? and not x == "_"}
    russian = [row['Russian']&.to_s]&.filter{|x|not x.blank? and not x == "_"}
    utility = row['Utility'].to_i
    use = row['Use'].to_i
    priority = utility * 100
    if dialect_from_name == "kanji"
      priority = use + utility * 100
      if use == 0
        priority = utility * 100 + 9999
      end
    elsif  dialect_from_name == "japanese"
      # detecting utility from kanji
      chars = japanese.map{|j|j.each_char.map{|ch| "#{ch}"}}.flatten.uniq
      translations_for_kanji = chars.map{|ch| Translation.joins(:word)\
        .find_by(word:{dialect_id:kanji_dialect_id, spelling:ch})}.filter{|t|!t.blank?}
      if translations_for_kanji.empty?
        if utility.nil? or  utility <= 0 or utility >= 10
          priority = 9999 + 100 * 100
        else
          priority = utility * 200
        end
      else
        if utility.nil? or utility <= 0 or utility >= 10 #i shoud think about if utility has any wight compa
          priority = 1000 + translations_for_kanji.map{|k| k&.priority.to_i}.max
        else
          priority = utility * 2 + translations_for_kanji.map{|k| k&.priority.to_i}.max
        end
      end
    end

    hiragana = romaji&.map{|j|j.safe_hiragana}
    if (hiragana.blank? or hiragana == ['=']or hiragana == ['_']) and dialect_from.name == 'japanese'
      hiragana = japanese.filter{|j|j.kana_with_symbol?}.map{|j|j.safe_hiragana}
    end
    hiragana&.each do |h|
      unless h.gsub(/\(|\)|\[|\]|\ |ー/,'').kana_with_symbol? || (romaji&.include?('nna') && !hiragana&.include?('な'))
        puts "unkaninized hiragana #{hiragana} for word #{japanese}"
      end
      if (h.blank? or h == '=') and dialect_from.name == 'japanese'
        puts "missing reading #{romaji} for word #{japanese}"
        next
      end
      last_ch = japanese.first[-1]
      if last_ch.hiragana? and japanese.all?{|j|j[-1] == last_ch}
        puts "suspicious reading #{romaji} for word #{japanese}" if h[-1]!= last_ch
      end
    end
    if (hiragana.blank? or hiragana == ['=']or hiragana == ['_']) and dialect_from.name == 'japanese'
      puts "missing readings #{romaji} for word #{japanese}"
      next
    end
    last_ch = japanese.first[-1]
    if last_ch.hiragana? and japanese.all?{|j|j[-1] == last_ch} and hiragana.any?{|h|h[-1] == last_ch}
      hiragana.filter!{|h|h[-1] == last_ch or (last_ch == 'は' and h[-1] =='わ')}
    end
    hiragana&.uniq!&.sort!
    # key = japanese + "|" + hiragana
    # existing_word_translations = existing_translations[key]
    existing_words = nil
    Subsets.each_subset(hiragana) do |hiragana_subset|
      next if hiragana_subset.blank? and dialect_from_id == japanese_dialect_id #at least one reading should match
      japanese.each do |w0|
        key =  w0 + "|" + hiragana_subset.sort.join('|')
        existing_words = existing_jap_words[key]
        break if existing_words
      end
      break if existing_words
    end
    puts "not found kanji #{japanese}" if not existing_words and dialect_from_id == Dialect.kanji.id

    existing_word_translations = existing_words&.map{|w|w.translations.filter{|t|t.user_id==user.id and t.suffix == w_suffix}}&.flatten || []
    if existing_words.blank? #creating wor if not found
        word = Word.new
        word.spelling = japanese.first
        word.dialect_id = dialect_from_id
        word_saved = word.save
        word = word.reload
        counter_word = counter_word + 1
        existing_words = [word]
        Subsets.each_subset(hiragana) do |hiragana_subset|
          japanese.each do |w0|
            key =  w0 + "|" + hiragana_subset.sort.join('|')
            existing_jap_words[key] ||= existing_words
          end
        end
    else
      puts "multiple words for #{japanese} #{romaji}" if existing_words.length > 1
      word = existing_words.first
    end

    array = [[dialect_from_id,japanese],[english_dialect_id,english],[russian_dialect_id,russian],[kana_dialect_id,hiragana]]

    if word.blank? or word.spelling.blank?
      puts "failed to construct or find word for #{japanese} #{romaji}"
      next
    end
    w_suffix0  =w_suffix
    # puts "updating key: #{key}"
    array.each do |dialect_id, translation_texts|
      #translation_texts.each do |translation_text|
      if dialect_id.blank? or translation_texts.blank?
        #  puts "skipped_blank: #{translation_text}"
        next
      end
      w_suffix = dialect_id== kana_dialect_id ? nil: w_suffix0;
      translations = existing_word_translations.filter{|ewt| ewt.translation_dialect_id == dialect_id and ewt.suffix == w_suffix and ewt.user_id == user.id}&.uniq
      # cleaning up duplicate translatino which may be skipped couse unconfirmed removes extra duplicates
      if not [dialect_from_id,kana_dialect_id].include?(dialect_id) and dialect_from_id!=Dialect.kanji.id and translations and translations.length > 1
        puts "multiple translations for #{japanese} #{romaji}"
        # cleanup duplicates should be for not kana or alt writing
        translations&.drop(1)&.each do |t|
          counter_deleted = counter_deleted + 1
          puts "REMOVED DUPLICATE [id:#{t.id}] #{word.spelling} #{romaji} translates to #{Dialect.find_by(id:dialect_id).name} as '#{t.translation}' by #{User.find_by(id:t.user_id).name}"
          t.delete
        end
      end

      word = Word.eager_load(:translations).find_by(id:word.id)
      #no need for duplicate translation for alt forms and readings
      if [kana_dialect_id, dialect_from_id].include?(dialect_id) or dialect_from_id==Dialect.kanji.id
        translation_texts.to_a.filter! do |translation_text| #filters
          translation = word.translations.find_by(translation_dialect_id: dialect_id,suffix: w_suffix,translation: translation_text, user_id: user.id)
          translation = word.translations.find_by(translation_dialect_id: dialect_id,suffix: w_suffix,translation: translation_text) if translation.blank?
          puts ">>>kono translation confirmed #{translation.translation}" if tracked_ids.include?(word.id) and translation
          puts ">>>kono translation unconfirmed #{translation_text}" if tracked_ids.include?(word.id) and not translation
          overriden_translations[translation.id] = true unless translation.blank?
          counter_confirmed = counter_confirmed + 1 unless translation.blank?
          skipped_same_kana = skipped_same_kana + 1 unless translation.nil?
          # puts "skipped_same: #{translation_text} with translation id #{translation.id} and text #{translation.translation}"
          translation.blank?
        end
      end

      translation = translations&.first
      translation_texts.each do |translation_text|
        next if translation_text == word.spelling and dialect_id == dialect_from_id
        if [dialect_from_id,kana_dialect_id].include?(dialect_id) or dialect_from_id==Dialect.kanji.id or not translation
          #multiple translations for kana unless skipped exactly same previously
          translation = Translation.new
          puts ">>>kono translation created #{translation.translation}" if tracked_ids.include?(word.id)
        end
        if (translation.translation == translation_text and translation.priority == priority and translation.word_id = word.id)
          counter_confirmed = counter_confirmed + 1
          puts ">>>kono translation confirmed other way #{translation.translation}" if tracked_ids.include?(word.id)
          overriden_translations[translation.id] = true
          # puts "skipping [#{translation.translation}] == [#{translation_text}]"
        else
          if translation.id.nil?
            counter_saved = counter_saved + 1
          else
            puts "# #{word.spelling} translation updated from #{translation.priority}:  #{translation.translation} to #{priority}: #{translation_text}"
            counter_updated = counter_updated + 1
          end
          # puts "[#{translation.translation}] != [#{translation_text}] or [#{translation.priority}] != [#{priority}]"
          # puts "#{user.name}: [id:#{translation.id}] #{key} translates to #{Dialect.find_by(id:dialect_id).name} as '#{translation_text}'"
          translation.word_id = word.id
          translation_text = translation.translation + ' ' + translation.translation if overriden_translations[translation.id]
          translation.translation = translation_text
          translation.translation_dialect_id = dialect_id
          translation.user = user
          translation.priority = priority
          translation.suffix = w_suffix
          unless translation.save
            puts "saving #{key.to_s} => #{translation_text} failed #{translation.errors}"
          end
          puts ">>>kono translation updated #{translation.translation}" if tracked_ids.include?(word.id)
          overriden_translations[translation.id] = true
          existing_word_translations.append(translation)
          word.translations.append(translation)
          # puts "#{key.to_s} => #{translation_text} saved"
        end
      end
    end
  end
  puts "checked #{counter} rows; #{counter_confirmed} are confirmed;  #{counter_updated} are updated;  new #{counter_saved} are saved"
  puts "#{counter_word} new source words are saved, while #{skipped_same_kana} duplicate creation skipped "
  puts "finished parsing csv for #{provider}"
  overriden_translations.each do |t_id, overriden|
    t= Translation.find_by(id:t_id)
    if t and not overriden
      puts "removing unconfirmed translations  #{Word.find_by(id:t.word_id).spelling} #{t.translation}"
      t.delete
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
  parse_csv(provider,file_path,Dialect.kanji)
end
puts "finished seeding kanji"

jap_files =
  [
#   ["HirokoStormSeed",Rails.root.join('db', 'seeds', 'japanese_to_english_translations.csv')],
    ["YarxiSeed",Rails.root.join('db', 'seeds', 'yarxi', 'DictionaryRussianKanji.csv')],
    ["YarxiComboSeed",Rails.root.join('db', 'seeds', 'yarxi', 'DictionaryRussianCompound.csv')],
    ["JishopSeed",Rails.root.join('db', 'seeds', 'jishop', 'DictionaryEnglishKanji.csv')],
    ["JishopComboSeed",Rails.root.join('db', 'seeds', 'jishop', 'DictionaryEnglishCompound.csv')]
  ]
jap_files.each do |provider,file_path|
  parse_csv(provider,file_path,Dialect.japanese)
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

puts "chking uniqueness"
existing_jap_words = Word.existing_japanese_by_key
existing_jap_words.values.each do |same_words|
  same_words.uniq.drop(1).each do |word|
    puts "word duplicate deleted #{word.spelling}"
    TemplateWordProgress.where(word_id: word.id).each{|twp|twp.delete}
    word.translations.each{|t|t.delete}
    word.delete
    deleted_without_kana = deleted_without_kana + 1
    deleted_jap_duplicated = deleted_jap_duplicated + 1
  end
end
puts "cheking if existing words have readings"
Word.where(dialect_id: japanese_dialect_id).each do |word|
  kana = word.translations.where(translation_dialect_id:kana_dialect_id)&.first&.translation.to_s
  if kana.blank?
    puts "word without kana #{word.spelling}"
    TemplateWordProgress.where(word_id: word.id).each{|twp|twp.delete}
    word.translations.each{|t|t.delete}
    word.delete
    deleted_without_kana = deleted_without_kana + 1
    next
  else
    kept_with_kana = kept_with_kana +1
  end
end
puts "deleted #{deleted_without_kana} jap word without kana and #{deleted_jap_duplicated} duplicates"
puts "#{kept_with_kana} jap words and total #{existing_jap_words.size} diffrent keys ar kept"
