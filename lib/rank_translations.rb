require 'csv'
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
  .map{|w,m| w.strip}
puts('---------------------------------------')
# puts(frequent_words.take(100))
word_list = []
word_set = Set.new
kanji_set = Set.new
words_by_key = {}
words_by_kanji = {}
japanese_dialect_id =  Dialect.find_by(name:'japanese').id
kana_dialect_id =  Dialect.find_by(name:'kana').id
level = 1
level_folders.take(1).each do |level_folder|
  csv_text =Dir.glob([level_folder, '/*.csv'].join).map{|file| File.read(file)}.join
  csv_text.gsub!('"','')
  csv = CSV.parse(csv_text, :headers => %i[kanji reading meaning frequency], :encoding => 'UTF-8', :col_sep => '|')
  csv.each do |row|
    word = [(row[:kanji].nil? || row[:kanji].strip.empty?) ? row[:reading].strip : row[:kanji].strip, row[:reading].strip, level, level + csv.length]
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
  level = level + csv.length
end

n = 0
frequent_words.map{|w|w.gsub('（',' ').gsub('）','').split('、')}.flatten.each do |line|
  n = n + 1
  kana = false
  if line.include?('【')
    kanji = line.split('【')[0]
    kana = line.split('【')[1].gsub('】','')
  else
    kanji = line
  end
  if kanji_set.include?(kanji)
    if kana && words_by_key[[kanji,kana]]
      w = words_by_key[[kanji,kana]]
      w[3] = w[2] + n
    else
      words_by_kanji[kanji].each{|w| w[3] = w[2] + n}
    end
    # puts words_by_kanji[kanji][0]
  else
    unless kana
      translation = Translation.joins(:word)\
          .find_by(word: {dialect_id: japanese_dialect_id, spelling:kanji}, translation_dialect_id: kana_dialect_id)
      if translation.nil?
        translation = Translation.joins(:word)\
          .where("spelling LIKE '%#{kanji} %'")\
          .find_by(word: {dialect_id: japanese_dialect_id}, translation_dialect_id: kana_dialect_id)
      end
      if translation.nil?
          translation = Translation.joins(:word)\
              .find_by(word: {dialect_id: japanese_dialect_id}, translation_dialect_id: kana_dialect_id,  translation: kanji)
      end
      if translation.nil?
          translation = Translation.joins(:word)\
            .where("translation LIKE '%#{kanji} %'")\
            .find_by(word: {dialect_id: japanese_dialect_id}, translation_dialect_id: kana_dialect_id)
      end
      unless translation.nil?
        kanji = translation.word.spelling
        kana = translation.translation
      end
    end

    if kana
      word = [kanji, kana,level,666+n]
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
      puts "#{kanji} - #{kana}"
    end
  end
end

puts("#{word_list.length}---------------------------------------")
word_list.sort_by!{|w| w[3]}
# puts word_list.take(1000).map{|w| w.to_s}

rank = 0
word_list.each do |word|
  rank += 1
  kanji = word[0]
  kana = word[1]
  translation = Translation.joins(:word)\
      .find_by(word: {dialect_id: japanese_dialect_id, spelling:kanji}, translation_dialect_id: kana_dialect_id, translation: kana)
  if translation.nil?
    translation = Translation.joins(:word)\
      .where("spelling LIKE '%#{kanji} %' AND translation LIKE '%#{kana} %'  ")\
      .find_by(word: {dialect_id: japanese_dialect_id}, translation_dialect_id: kana_dialect_id)
  end
  if translation.nil? && kanji.contains_katakana?
    translation = Translation.joins(:word)\
        .find_by(word: {dialect_id: japanese_dialect_id, spelling:kanji}, translation_dialect_id: kana_dialect_id)
  end
  if translation.nil?
    puts word.to_s
  else
    translation2 = Translation.find_by(rank:rank)
    translation2.update_attribute(:rank, translation.rank)
    translation.update_attribute(:rank, rank)
  end
end
