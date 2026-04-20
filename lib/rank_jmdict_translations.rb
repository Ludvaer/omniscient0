# converts priority fo jmdict imported translation to rank
user = User.system_user('JMDictParser')
target_dialect = Dialect.japanese
[Dialect.english, Dialect.russian].each do |source_dialect|
  puts "#{[source_dialect.name,target_dialect.name]}"
  translations =
      Translation.joins(:word)
      .where(word: {dialect_id: target_dialect.id}, translation_dialect_id:source_dialect.id, user_id: user.id)
      .order(:priority)
  translations.each_with_index do |translation,i|
    unless translation.rank == i + 1
      translation.update!(rank: i + 1)
    end
  end
  if translations.size > 0
    puts "updated #{translations.size} translation"
  end
end
