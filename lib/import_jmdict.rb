# The purpose of this script is to load jmdict and
# update ranks of existing words based on jmdict data
require 'nokogiri'
require 'subsets'
require Rails.root.join('lib/core_ext/string/kana_extensions')
words_to_track = [171,2817, 62332, 10988, 15152]
strings_to_track = ['聴く','所','眼','悪い']
changed_translations = 0


def add_without_go_prefix!(set, prefix = "御")
  set.to_a.each do |word|   # iterate over a snapshot
    next unless word.start_with?(prefix)

    stripped = word.delete_prefix(prefix)
    set.append(stripped) unless stripped.empty?
  end
  set
end

def group_meanings_by_added_string(meanings)
  meanings.each_with_object(Hash.new { |h, k| h[k] = [] }) do |meaning, grouped|
    text = meaning.strip

    added_strings = text.scan(/\{([^}]+)\}/).flatten
    key = added_strings.empty? ? nil : added_strings.join(' ').gsub('~','')

    cleaned = text.gsub(/\{[^}]+\}/, '').strip
    cleaned = cleaned.gsub(/\s+/, ' ')

    grouped[key] << cleaned unless cleaned.empty?
  end
end


puts "-" * 40
puts ("-" * 14) + "  START NEW RUN   " + ("-" * 14)
puts "-" * 40
user = User.system_user('JMDictParser')
puts "user id #{user.id}"
file_path = 'D:\input\books\japanese\Dictionary\JMdict'  # or JMdict.xml if not English-only
jap_dialect_id = Dialect.japanese.id
english_dialect_id = Dialect.english.id
ru_dialect_id = Dialect.russian.id
kana_dialect_id = Dialect.kana.id
puts "requesting words"
existing_jap_words = Word.existing_japanese_by_key
dialect_by_lang = {'eng' => english_dialect_id,  'rus' => ru_dialect_id}
puts 'existing examples'
existing_jap_words.drop(0).take(20).each{|x,y|puts x.to_s}
puts "requesting translatinos"
existing_translations = Translation.where(user_id:user.id)
puts "mapping translatinos"
overriden_translations = existing_translations.map { |t|[t.id,false]  }.to_h

puts "go parse dictionary"
queue = []
counter = 0
# start processing jmdict file
File.open(file_path) do |file|
  doc = Nokogiri::XML(file)

  # doc.xpath('//entry').drop(0).take(50).each do |entry|
  doc.xpath('//entry').each do |entry|
    if (queue.length > 0)
      data = queue.pop
    else
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
    end

    # Optional: frequency tags
    freq_tags = entry.xpath('k_ele/ke_pri | r_ele/re_pri').map(&:text)
    # puts freq_tags
    nf_tag = freq_tags.find { |tag| tag.start_with?('nf') }
    nf_rank = nf_tag&.gsub('nf', '')&.to_i || 50 # => 1 to 48 or nil
    news_rank = freq_tags.find { |tag| tag.start_with?('news') }&.gsub('news', '')&.to_i || 15
    ichi_rank = freq_tags.find { |tag| tag.start_with?('ichi') }&.gsub('ichi', '')&.to_i || 15
    spec_rank = freq_tags.find { |tag| tag.start_with?('spec') }&.gsub('spec', '')&.to_i || 15
    gai_rank = freq_tags.find { |tag| tag.start_with?('gai') }&.gsub('gai', '')&.to_i || 15
    if nf_rank >= 50
      nf_rank = [[news_rank*2, ichi_rank, spec_rank*3, gai_rank*4].min*5, 50].min
    end
    rank = nf_rank * 3 + [news_rank, ichi_rank, spec_rank, gai_rank].min
    # ===== YOUR DATABASE INSERTION LOGIC GOES HERE =====
    # You now have:
    # - `kanji_elements`: array of kanji forms
    # - `reading_elements`: array of kana readings
    # - `meanings`: array of hashes like { language: 'eng', text: 'language' }
    # - `freq_tags`: frequency indicators like 'nf10', 'ichi1', etc.

    if(rank > 140)
      next
    end
    counter += 1
    puts counter if counter % 200 == 0
    elements = if kanji_elements.length > 0 then kanji_elements else reading_elements end
    add_without_go_prefix!(elements)
    add_without_go_prefix!(reading_elements,'お') if kanji_elements.any? { |word| word.start_with?("御") }
    reading_elements =reading_elements.filter{|re|re.kana_with_symbol?}.map{|a|a.safe_hiragana}
    last_ch = reading_elements&.first[-1]
    if last_ch.hiragana? and reading_elements&.all?{|j|j[-1] == last_ch} and reading_elements&.any?{|h|h[-1] == last_ch}
      reading_elements.filter!{|h|h[-1] == last_ch or (last_ch == 'は' and h[-1] =='わ')}
    end
    reading_elements&.uniq!&.sort!
    is_tracked = elements.any?{|e|strings_to_track.include?(e)}

    key = existing_words = nil
    Subsets.each_subset(reading_elements) do |reading_element_subset|
      elements.each do |w0|
        key =  w0 + "|" + reading_element_subset.sort.join('|')
        existing_words = existing_jap_words[key]
        break if existing_words
      end
      break if existing_words
    end
    meanings = meanings.group_by{|m|m[:language]}
       .map { |lang,ms| [lang, group_meanings_by_added_string(ms.map {|m|m[:text]})] }

    if is_tracked || existing_words&.any?{|w|words_to_track.include?(w.id)}
      is_tracked ||= true
      puts "Word: #{elements.join(', ')}"
      puts "Readings: #{reading_elements.join(', ')}"

      puts "Meanings: #{meanings}"
      puts "priority: #{rank} (nf_rank#{nf_rank} ichi_rank#{ichi_rank} spec_rank#{spec_rank} gai_rank#{gai_rank} news_rank#{news_rank})"
    end
    word_to_edit = nil

    if existing_words
      # Translation.where(word_id: existing_word.map{|x|x.id}).pluck(:translation).join(' | ')
      # I suddenly realized no need to reload words if tranlstions preloaded
      translations = existing_words.map{|word| word.translations.map{|t| t.translation}.flatten}.flatten
      #puts "existing translations: #{translations}"
      puts "multiple existing words #{existing_words.map(&:spelling)}" if existing_words.length > 1

      word_to_edit = existing_words.first
      existing_words.each do |w|
          #w.update!(rank: rank) # do not update rank for existing words
          if w.spelling in kanji_elements and not word_to_edit
            word_to_edit = w
          end
      end

      # word_to_edit.translations.each{ |t| t.delete  }
      # word_to_edit.delete
      # puts "remove #{word_to_edit.spelling}"
    else
      puts "no existing words found for key #{key}"
    end

    saved = nil
    if word_to_edit
      puts "existing words #{existing_words.map(&:id)}: #{existing_words.map(&:spelling)}" if is_tracked
    else
      word_to_edit = Word.new
      word_to_edit.spelling = elements.first
      if word_to_edit.spelling.nil? or word_to_edit.spelling.empty?
         word_to_edit.spelling = reading_elements.first
      end
      word_to_edit.dialect_id = jap_dialect_id
      word_to_edit.rank = rank
      if word_to_edit.spelling
        saved = word_to_edit.save
      puts "saved #{saved} for word #{word_to_edit.id}:#{word_to_edit.spelling}" if is_tracked
      else
        puts "not saved #{saved} for word #{word_to_edit.id}:#{word_to_edit.spelling}"
      end
    end

    if not elements.is_a?(Array)
      elements = [elements]
    end
    #TODO: remove obsolete alternative writings
    #update alternative writings as translations to japanese
    elements.each do |kanji|
      unless word_to_edit.spelling == kanji
        tt = Translation.find_or_create_by!(
          translation: kanji,
          translation_dialect_id: jap_dialect_id,
          word_id: word_to_edit.id
          )
        if tt.user_id == 0
          tt.update!(user_id: user.id,priority: rank)
        end

        tt.save
        puts "saved #{saved} for word #{word_to_edit.id}:#{word_to_edit.spelling} alt as #{tt.translation}"  if is_tracked
        overriden_translations[tt.id] = true
      end
    end


    if not reading_elements.is_a?(Array)
      reading_elements = [reading_elements]
    end
    if reading_elements.blank?
      reading_elements = word_to_edit.filter{|w|w.kana_with_symbol?}.uniq # [word_to_edit.spelling.safe_hiragana]
      puts "set reading #{word_to_edit.spelling} to #{reading_elements}" if is_tracked
    end
    if reading_elements.blank?
      puts "skip '#{word_to_edit.spelling}' without reading"
      next
    end

    #TODO: remove obsolete alternative writings
    #update alternative writings as translations to japanese
    reading_elements.each do |reading|
      tt = Translation.find_or_create_by!(
        translation: reading,
        translation_dialect_id: kana_dialect_id,
        word_id: word_to_edit.id
        )
      if tt.user_id == 0
        tt.update!(user_id: user.id,priority: rank)
      end
      tt.save
      overriden_translations[tt.id] = true
      puts "saved #{saved} for word #{word_to_edit.id}:#{word_to_edit.spelling} transcribed as #{tt.translation}" if is_tracked
    end

    #TODO: make language any
    meanings.each do |lang, by_suffix|
      by_suffix.each do  |suffix, texts|
        translation = Translation.find_or_create_by!(
          translation_dialect_id: dialect_by_lang[lang],
          user: user,
          word_id: word_to_edit.id,
          suffix: suffix&.gsub('～','')
          )
          new_translation = texts.filter{|t| not t.include?('(см.)')}.join(', ')
        changed_translations += 1 if translation.translation != new_translation
        puts "updating the existing #{translation.priority}: #{translation.translation}" if is_tracked
        translation.update!(
          priority: rank,
          translation: new_translation
        )
        overriden_translations[translation.id] = true
        saved = translation.save
        puts "saved #{saved} for word #{word_to_edit.id}:#{word_to_edit.spelling} translated as #{translation.translation} with priority #{translation.priority}"  if is_tracked
        #TODO: remove unconfirmed translations and non translated words
      end
    end
    #puts "-" * 40
  end
end
puts "finished parsing"
deleted = 0
kept = 0
overriden_translations.each do |t_id, overriden|
  if overriden
    kept+=1
  else
    t = Translation.find_by(id:t_id)
    puts "removing unconfirmed translations  #{Word.find_by(id:t&.word_id)&.spelling} #{t&.translation}"
    t&.delete
    deleted += 1
  end
end
puts "#{kept} keeped"
puts "#{deleted} deleted"
