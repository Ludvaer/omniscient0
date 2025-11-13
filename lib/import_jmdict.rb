require 'nokogiri'

user = User.system_user('JMDict_import')
file_path = 'D:\input\books\japanese\Dictionary\JMdict'  # or JMdict.xml if not English-only
jap_dialect_id = Dialect.japanese.id
kana_dialect_id = Dialect.kana.id
existing_jap_words = Word.existing_japanese_by_key
puts 'existing examples'
existing_jap_words.drop(200).take(150).each{|x,y|puts x.to_s}

File.open(file_path) do |file|
  doc = Nokogiri::XML(file)

  doc.xpath('//entry').drop(200).take(150).each do |entry|
    # Extract kanji forms (may be absent for kana-only words)
    kanji_elements = entry.xpath('k_ele/keb').map(&:text)

    # Extract kana readings
    reading_elements = entry.xpath('r_ele/reb').map(&:text)

    # Extract meanings (only EN and RU)
    meanings = entry.xpath('sense').flat_map do |sense|
      sense.xpath('gloss').map do |gloss|
        lang = gloss['xml:lang'] || 'eng'
        next unless %w[eng rus].include?(lang)

        { language: lang, text: gloss.text }
      end.compact
    end

    # Optional: frequency tags
    freq_tags = entry.xpath('k_ele/ke_pri | r_ele/re_pri').map(&:text)
    nf_tag = freq_tags.find { |tag| tag.start_with?('nf') }
    nf_rank = nf_tag&.gsub('nf', '')&.to_i || 50 # => 1 to 48 or nil
    news_rank = freq_tags.find { |tag| tag.start_with?('news') }&.gsub('news', '')&.to_i || 3
    ichi_rank = freq_tags.find { |tag| tag.start_with?('ichi') }&.gsub('ichi', '')&.to_i || 3
    spec_rank = freq_tags.find { |tag| tag.start_with?('spec') }&.gsub('spec', '')&.to_i || 3
    gai_rank = freq_tags.find { |tag| tag.start_with?('gai') }&.gsub('gai', '')&.to_i || 3
    rank = nf_rank * 3 + [news_rank, ichi_rank, spec_rank, gai_rank].min
    # ===== YOUR DATABASE INSERTION LOGIC GOES HERE =====
    # You now have:
    # - `kanji_elements`: array of kanji forms
    # - `reading_elements`: array of kana readings
    # - `meanings`: array of hashes like { language: 'eng', text: 'language' }
    # - `freq_tags`: frequency indicators like 'nf10', 'ichi1', etc.

    if(rank > 100)
      next
    end

    word0 = kanji_elements.length > 0 ? kanji_elements[0] : reading_elements[0]
    key =  word0 + "|" + reading_elements.sort.join('|')
    existing_word = existing_jap_words[key]


    # Debug print
    puts "Word: #{kanji_elements.join(', ')}"
    puts "Readings: #{reading_elements.join(', ')}"
    puts "Meanings:"
    meanings.each { |m| puts "  (#{m[:language]}) #{m[:text]}" }
    puts "priority: #{nf_rank}"
    if existing_word
      translations  = Translation.where(word_id: existing_word.map{|x|x.id}).pluck(:translation).join(' | ')
      puts "existing translations: #{translations}"
    else
      puts "no existing words found for key #{key}"
    end

    puts "-" * 40
  end
end
