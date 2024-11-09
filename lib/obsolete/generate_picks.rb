#now let's make pick batch generation simultaion
# ActiveRecord::Base.logger = Logger.new(STDOUT)
user = User.find_by(name: 'Lurr')
center =  6771.0
std_err = 10138.0
slope = Math.sqrt(2)/(Math.sqrt(Math::PI)*std_err)  #multlier to put into 0.5*(1 + tanh(slope*(x-center))) to get needed sigmoid function
pick_size = 5
pick_count = 10
source_dialect_id = Dialect.find_by(name:'english').id
target_dialect_id =  Dialect.find_by(name:'japanese').id

maxpick = UserTranslationLearnProgress.maximum(:last_counter) + 1
learn_progress_count = UserTranslationLearnProgress
  .joins("INNER JOIN translations ON translations.id=user_translation_learn_progresses.translation_id")
  .joins("INNER JOIN words ON words.id=translations.word_id") #:word)
  .where("user_translation_learn_progresses.user_id = #{user.id} \
     AND translations.translation_dialect_id=#{source_dialect_id} \
     AND words.dialect_id=#{target_dialect_id}")
  # .where(user_id:user.id,translation:{translation_dialect_id:source_dialect_id},
  #    word:{dialect_id:target_dialect_id})
     .count
puts "maxpick = #{maxpick}; learn_progress_count = #{learn_progress_count};"
translations =
    Translation.joins(:word) # .left_outer_joins(:user_translation_learn_progresses)
    .joins("LEFT OUTER JOIN user_translation_learn_progresses \
       ON user_translation_learn_progresses.translation_id=translations.id \
       AND user_translation_learn_progresses.user_id=#{user.id}")
    .where(word:{dialect_id: target_dialect_id}, translation_dialect_id:source_dialect_id)
    .order(Arel.sql(
      "abs( COALESCE( \
      (1.0 - correct/(correct + failed + 0.01))*0.5^(0.1 * (#{maxpick} - last_counter)) \
      + (correct/(correct + failed + 0.01) - 0.5*(2 - tanh(#{slope}*(translations.rank-#{center}))) )*0.5^((#{maxpick} - last_counter)/#{learn_progress_count}) \
      ,0) + 0.5*(2 - tanh(#{slope}*(translations.rank-#{center}))) - 0.85)"
      # "abs(0.5*(2 - tanh(#{slope}*(translations.rank-#{center}))) - 0.85)"
      )).take(pick_size * pick_count)

translations.each do |trans|
   sigmoid = 0.5*(2 - Math.tanh(slope*(trans.rank-center)))
   picks = PickWordInSet
     .where("(correct_id = #{trans.id} OR picked_id = #{trans.id}) AND picked_id IS NOT NULL AND user_id=#{user.id}")
   correct_picks = picks.select{ |pick| Translation.find_by(id:pick.correct_id).word.spelling == Translation.find_by(id:pick.picked_id).word.spelling }
   estimated_prob = 0
   recent_part = 0
   longer_part = 0
   iterations = 0
   if picks.exists?
      utlp = UserTranslationLearnProgress.find_by(user_id: user.id, translation_id:trans.id)
      estimated_prob = correct_picks.size / (picks.size.to_f + 0.01)
      recent_part = (1 - estimated_prob) * 0.5**(0.1 * (maxpick - utlp.last_counter))
      longer_part = (estimated_prob - sigmoid)* 0.5**((maxpick - utlp.last_counter)/learn_progress_count)
      total_estimated_prob = recent_part + longer_part + sigmoid
      estimated_prob = total_estimated_prob
      iterations = maxpick - utlp.last_counter
   end
   puts "#{trans.word.spelling} -> #{trans.translation}
   with probablityy = #{estimated_prob}; after #{iterations} iterations\
   from estimated_prob = #{estimated_prob} while sigmoid = #{sigmoid}; \
   recent_part = #{recent_part}; longer_part = #{longer_part}"
end

puts "total size = #{translations.size}"
