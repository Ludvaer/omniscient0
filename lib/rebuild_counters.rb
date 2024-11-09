UserTranslationLearnProgress.delete_all
UserDialectProgress.delete_all
as = [Dialect.all.to_a,Dialect.all.to_a,User.all.to_a]
as[0].product(*as[1..-1]).each do |source_dialect,target_dialect,user|
  puts "#{[source_dialect.name,target_dialect.name,user.name]}"
  #iterate over PickWordInSet to reupdate UserTranslationLearnProgress
  imax = 0
  PickWordInSet.joins("INNER JOIN translations ON translations.id=pick_word_in_sets.correct_id")\
        .joins("INNER JOIN words ON words.id=translations.word_id")\
        .where("picked_id IS NOT NULL AND pick_word_in_sets.user_id=#{user.id} \
           AND translations.translation_dialect_id=#{source_dialect.id} \
           AND words.dialect_id=#{target_dialect.id}") \
        .order(:created_at) \
        .each_with_index do |p,i|
    is_correct = Translation.find_by(id:p.correct_id).word.spelling === Translation.find_by(id:p.picked_id).word.spelling
    [ p.correct_id, p.picked_id].uniq.each do |t_id|
      lp = UserTranslationLearnProgress.find_or_create_by(user_id:user.id,translation_id: t_id)
      if lp.correct.nil? || lp.failed.nil? || lp.last_counter.nil?
        lp.correct = 0
        lp.failed = 0
        lp.last_counter = 0
      end
      lp.last_counter = [i, lp.last_counter].max
      if is_correct
        lp.correct += 1
      else
        lp.failed += 1
      end
      lp.save
      imax = i
    end
  end
  if imax > 0
    UserDialectProgress.find_or_create_by(dialect_id: target_dialect.id, \
         user_id: user.id, source_dialect_id:source_dialect.id).update!(counter: imax)
    puts "updated last counter #{imax}"
  end
end

Dialect.all.to_a.product(Dialect.all.to_a).each do  |source_dialect,target_dialect,user|
  puts "#{[source_dialect.name,target_dialect.name]}"
  translations =
      Translation.joins(:word)
      .where('word.dialect_id':target_dialect.id, translation_dialect_id:source_dialect.id)
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
