class String

  def kana_with_symbol?
    return false if strip.empty?
    moji_type?(Moji::KANA | Moji::ZEN_SYMBOL)
  end

  def katakana_with_symbol?
    return false if strip.empty?
    moji_type?(Moji::KATA | Moji::ZEN_SYMBOL)
  end

  @@replacements1 = {
    'ō' =>'ou',
    'o:' =>'ou',
    'ē' =>'ee',
    'e:' =>'ee',
    'ā' =>'ou',
    'a:' =>'ou',
    'nn' =>'mn',
  }
  @@replacements2 = {
    'nn' =>'んn',
    'm' =>'ん',
    'まs' =>'ます',
    'でs' =>'です',
    't' =>'っ',
    'f' =>'フ',
  }
  def safe_hiragana
    downcase.gsub(Regexp.union(@@replacements1.keys), @@replacements1)\
    .hiragana.gsub(Regexp.union(@@replacements2.keys), @@replacements2)
  end
end
