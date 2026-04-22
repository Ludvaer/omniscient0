require 'csv'
require 'nokogiri'
require 'core_ext/string/kana_extensions'

# Word.all.joins(:translations) \
#   .group("words.id").order("MAX(translations.rank)")\
#   .each_with_index{|w,i| w.update_attribute(:rank, i)}
zero_translation = Translation.find_or_create_by!(id:0, word_id:0, user_id:0, translation_dialect_id:0, translation: "")
jap_folder = Rails.root.join('db', 'seeds','japanese')
level_folders = [
  Rails.root.join(jap_folder,'N5'),
  Rails.root.join(jap_folder,'N4'),
  Rails.root.join(jap_folder,'N3'),
  Rails.root.join(jap_folder,'N2'),
  Rails.root.join(jap_folder,'N1')
]
most_frequent_5000_file = Rails.root.join(jap_folder,'most_frequent_5000.csv')
csv_text = File.read(most_frequent_5000_file)
csv = CSV.parse(csv_text, :headers => true, :encoding => 'UTF-8', :col_sep => '|')
frequent_words = csv.map{|row| [row['Word'], row['Meaning']]} \
  .reject{|w,m| m.start_with?('p.','aux.','interj.','cp.','conj.')} \
  .map{|w,m| w&.strip}
puts('---------------------------------------')
# puts(frequent_words.take(100))
word_list = []
word_set = Set.new
kanji_set = Set.new
words_by_key = {}
words_by_kanji = {}
japanese_dialect_id =  Dialect.japanese.id
kana_dialect_id =  Dialect.kana.id
priority = 1
puts "parsing levels starts"
level_folders.each_with_index  do |level_folder, level|
  puts "parsing levels #{level}"
  #combine all the tables in level folder
  csv_text =Dir.glob([level_folder, '/*.csv'].join).map{|file| File.read(file)}.join
  csv_text.gsub!('"','')
  csv = CSV.parse(csv_text, :headers => %i[kanji reading meaning frequency], :encoding => 'UTF-8', :col_sep => '|')

  csv.each do |row|
    #word in this context is kanji, kana, base rank, current actual rank = max for this level
    word = [(row[:kanji].blank?) ? row[:reading].strip : row[:kanji].strip,
     row[:reading]&.strip,
     priority,
     priority +csv.length]
    word[1] = word[0] if word[0].kana_with_symbol?
    word[1]  = word[1].safe_hiragana if word[1].katakana_with_symbol?
    puts "non kana reading in levels #{word[0]} #{word[1]}" unless word[1].kana_with_symbol?
    # puts word
    unless word_set.include?(word)
      word_list.append(word)
      word_set.add(word)
      kanji_set.add(word[0])
      words_by_kanji[word[0]] ||= []
      words_by_kanji[word[0]].append(word)
      if word[1] != word[0]
        words_by_kanji[word[1]] ||= []
        words_by_kanji[word[1]].append(word)
      end
      key = [word[0],word[1]]
      unless words_by_key[key].nil?
        puts "duplicate |#{words_by_key[key]}| and |#{word}|"
      end
      words_by_key[key] = word
    end
  end
  priority += csv.length
end
puts "parsing levels finished, starting frequent words"

n = 0
frequent_words.map{|w|w.gsub('（',' ').gsub('）','').split('、')}.flatten.each do |line|
  n = n + 1
  kana = nil
  if line.include?('【')
    kanji = line.split('【')[0].split(' ').first.strip
    kana = line.split('【')[1].gsub('】','').split(' ').first.strip
    kana = kanji if not kana and kanji&.kana_with_symbol? #I think some kana might be broken for kana only words
  else
    kanji = line.split(' ').first.strip
  end
  kana = kana&.safe_hiragana if kana&.kana_with_symbol?
  kana = kanji&.safe_hiragana if kana.blank? and kanji&.kana_with_symbol?
  # puts "non kana reading in frequncy [#{line}] #{kanji} #{kana}" unless kana&.kana_with_symbol?
  if kanji_set.include?(kanji)
    if kana && words_by_key[[kanji,kana]]
      w = words_by_key[[kanji,kana]]
      w[3] = w[2] + n
    else
      words_by_kanji[kanji].each{|w| w[3] = w[2] + n}
    end
    # puts words_by_kanji[kanji][0]
  else
    if kanji.kana_with_symbol?
      translation = Translation.eager_load(:word).order('word.rank')\
          .where(word: {dialect_id: japanese_dialect_id, spelling:kanji}, translation:kanji, translation_dialect_id: kana_dialect_id).first
      translation = Translation.eager_load(:word).order('word.rank')\
          .where(word: {dialect_id: japanese_dialect_id}, translation:kanji, translation_dialect_id: kana_dialect_id).first if translation.blank?
      unless translation.blank?
        puts "#{kanji}: #{kana} -> #{translation.word.spelling}: #{translation.translation}"
        kanji = translation.word.spelling
        kana = translation.translation
      end
    end
    if kana.blank?
      kanji_base = kanji#.split(' ').first
      translation = Translation.joins(:word).order(:rank)\
          .find_by(word: {dialect_id: japanese_dialect_id, spelling:kanji_base}, translation_dialect_id: kana_dialect_id)
      if translation.nil?
        word = Translation.eager_load(:word).order(:rank).find_by(
          word: {dialect_id: japanese_dialect_id},
          translation_dialect_id: japanese_dialect_id,
          translation: kanji_base
         )&.word
        translation = Translation.order(:id).find_by(word_id: word.id,  translation_dialect_id: kana_dialect_id) if word
      end
      if translation.nil? and not kanji.kana_with_symbol? #search similar word if it's not juist kana
        translation = Translation.eager_load(:word)\
          .where("spelling LIKE '%#{kanji_base}%'")\
          .where(word: {dialect_id: japanese_dialect_id}, translation_dialect_id: kana_dialect_id)
          .order("CHAR_LENGTH(word.spelling), word.rank").first
          puts "#{kanji_base} -> #{translation.word.spelling}" if translation
      end
      if translation.nil?
          kanji_translation = Translation.eager_load(:word)\
            .where("translation LIKE '%#{kanji_base}%'")\
            .order("CHAR_LENGTH(translation), word.rank") \
            .find_by(word: {dialect_id: japanese_dialect_id}, translation_dialect_id: japanese_dialect_id)
          if kanji_translation
            translation = Translation.eager_load(:word)\
                         .find_by(word_id: kanji_translation.word_id, translation_dialect_id: kana_dialect_id)
          end
          puts "#{kanji_base} -> #{translation.word.spelling}" if translation
      end
      # if translation.nil?
      #     translation = Translation.eager_load(:word)\
      #         .find_by(word: {dialect_id: japanese_dialect_id}, translation_dialect_id: kana_dialect_id,  translation: kanji_base)
      # end
      # if translation.nil? and kanji.kana_with_symbol? #search word in kana
      #     translation = Translation.eager_load(:word)\
      #       .where("translation LIKE '%#{kanji_base}%'")\
      #       .where(word: {dialect_id: japanese_dialect_id}, translation_dialect_id: kana_dialect_id)
      #       .order("CHAR_LENGTH(translation)").first
      #     puts "#{kanji_base} -> #{translation.translation}" if translation
      # end


      unless translation.nil?
        kanji = translation.word.spelling
        kana = translation.translation
      end
    end

    if not kana.blank?
      word = [kanji, kana,priority,priority+n] #add it as added level after n5
      unless word_set.include?(word)
        word_list.append(word)
        word_set.add(word)
        kanji_set.add(word[0])
        words_by_kanji[word[0]] ||= []
        words_by_kanji[word[0]].append(word)
        if word[1] != word[0]
          kanji_set.add(word[1])
          words_by_kanji[word[1]] ||= []
          words_by_kanji[word[1]].append(word)
        end
      end
      # puts word
    else
      puts "missing kana ? #{kanji} - #{kana}"
    end
  end
end

puts("#{word_list.length}---------------------------------------")
word_list.sort_by!{|w| w[3]}
#

#now we will use words from word_list to help ranking rest of the words
rank = 0
english_dialect_id =  Dialect.find_by(name:'english').id
russian_dialect_id =  Dialect.find_by(name:'russian').id
replacements = {
  '２０' => '二十',
  '１０' => '十',
  '１' => '一',
  '２' => '二',
  '３' => '三',
  '４' => '四',
  '５' => '五',
  '６' => '六',
  '７' => '七',
  '８' => '八',
  '９' => '九',
  'ご飯' => '御飯',
}
word_list.each do |word|
  rank += 1
  kanji = word[0]
  kanji.gsub(Regexp.union(replacements.keys), replacements)
  kana = word[1].safe_hiragana
  translation = Translation.eager_load(:word)\
      .find_by(word: {dialect_id: japanese_dialect_id, spelling:kanji}, translation_dialect_id: kana_dialect_id, translation: kana)
  if translation.nil?
    word_ids = Translation.eager_load(:word).order(:rank).where(
      word: {dialect_id: japanese_dialect_id},
      translation_dialect_id: japanese_dialect_id,
      translation: kanji
    ).pluck(:word_id)
    translation = Translation.eager_load(:word)\
        .find_by(word: {id:word_ids}, translation_dialect_id: kana_dialect_id, translation: kana)
  end
  if translation.nil?
    #make sure if things like that are sql safe or else
    translation = Translation.eager_load(:word)\
      .where("spelling LIKE '%#{kanji} %' AND translation LIKE '%#{kana} %'  ")\
      .find_by(word: {dialect_id: japanese_dialect_id}, translation_dialect_id: kana_dialect_id)
  end
  if translation.nil? && kanji.kana_with_symbol?
    translation = Translation.eager_load(:word)\
        .find_by(word: {dialect_id: japanese_dialect_id, spelling:kanji}, translation_dialect_id: kana_dialect_id)
  end
  if translation.blank? && kanji.first == 'お' && kana.first == 'お' #handle o prefix
    translation = Translation.eager_load(:word)\
        .find_by(word: {dialect_id: japanese_dialect_id, spelling:kanji[1..]}, translation_dialect_id: kana_dialect_id, translation: kana[1..])
    if translation.nil?
      #make sure if things like that are sql safe or else
      translation = Translation.eager_load(:word)\
        .where("spelling LIKE '%#{kanji[1..]} %' AND translation LIKE '%#{kana[1..]} %'  ")\
        .find_by(word: {dialect_id: japanese_dialect_id}, translation_dialect_id: kana_dialect_id)
    end
  end
  if translation.nil?
    puts  "not found a word to rank #{word.to_s}"
  else
    word = translation.word
    word_id = translation.word.id
    word2 = Word.find_by(rank:rank, dialect_id: japanese_dialect_id)
    word2&.update!(rank: rank)
    word.update!(rank: rank)

    # [english_dialect_id,russian_dialect_id].each do |dialect_id|
    #   translations1 = Translation.eager_load(:word).where(word_id:word_id, translation_dialect_id:dialect_id )
    #   if translations1
    #     translations1.each do |translation1|
    #       translation2 = Translation.eager_load(:word).find_by(rank:rank, translation_dialect_id:dialect_id,suffix:translation1.suffix, user_id: translation1.user_id)
    #       translation2&.update!(rank: translation1.rank)
    #       translation1.update!(rank: rank)
    #     end
    #   else
    #     puts "found but not in #{dialect_id} is #{word.to_s}"
    #   end
    # end
  end
end
puts("#{word_list.length}---------------------------------------")
puts word_list.take(1000).map{|w| w.to_s}
