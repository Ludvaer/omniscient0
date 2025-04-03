romaji = "ironna"
puts romaji&.downcase&.gsub('nn', 'んn').hiragana.to_s.gsub('m', 'ん')
