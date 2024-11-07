user = User.find_by(name: 'Lurr')
current_user = user
source_dialect_id = [Dialect.find_by(name:'english').id]
target_dialect_id =  [Dialect.find_by(name:'japanese').id]
pick_size = 9
pick_count = 10

def sum_sqr(i)
  i * (2 * i + 1) * (2 * i - 1) / 12.0
end
def sum_sqr_d(i1,i2)
  sum_sqr(i2) - sum_sqr(i1)
end

all_eligible_translations =
    Translation.joins(:word)
    .where(word: {dialect_id: target_dialect_id}, translation_dialect_id:source_dialect_id)
prob_by_rank = { 0=>1.0, all_eligible_translations.size+1=>0.0  }
# semi fake border values
# need to do that on sider or calculation might sail away with average slope being wrong sign

progresses = UserTranslationLearnProgress
  .joins("INNER JOIN translations ON translations.id=user_translation_learn_progresses.translation_id")
  .joins("INNER JOIN words ON words.id=translations.word_id") #:word)
  .where("user_translation_learn_progresses.user_id = #{user.id} \
     AND translations.translation_dialect_id IN (?) \
     AND words.dialect_id IN (?)",source_dialect_id,target_dialect_id)
maxpick = progresses.maximum(:last_counter) + 1
learn_progress_count = progresses.count
puts "#{learn_progress_count} translations with total #{maxpick} attempts"
progresses.each do |progress|
     rank = progress.translation.rank
     estimated_prob =  progress.correct / (progress.correct + progress.failed + 0.01)
     short = (1 - estimated_prob) * (0.5**(0.1 * (maxpick - progress.last_counter)))
     long = (estimated_prob - 0)* (0.5**((maxpick - progress.last_counter)/learn_progress_count))
     prob_by_rank[rank] = short + long
     puts "#{ progress.correct}/#{progress.correct + progress.failed} = #{estimated_prob} => \
      #{short} + #{long} = #{prob_by_rank[rank]}"
end
# I do not fit anything or estimate probabilities
# Then, I pretend derivative of empiric probabilities over rank it is a normal distribution
# Then I pretend that corresponding 1/2(2-erf) is a sigmoid function
# That reflects probability to answer correctly
# which is likely horribly wrong thing
# I don't think that resulting sigmoid is anywhere near least squares or any other common metric
# so I call it guesstimate rather then fit
# this block calcultes average rank of negative slope which guesstimates center of sigmoid
weighted_sum, weight_sum = 0, 0
prob_by_rank.sort_by{|pair| pair[0]}.each_cons(2) do |pair1, pair2|
  i1, p1 = pair1
  i2, p2 = pair2
  # slope = (p2 - p1) / (i2 - i1).to_f
  # weighted_sum += slope * (i1 + i2) * (i2 - i1) / 2.0 #kinda sum of slope*i for i from i1 to i2 (in midpoints)
  # weight_sum += slope * (i2 - i1).to_f #sum of slopes for each i
  weighted_sum -= (p2 - p1) * (i1 + i2) / 2.0 #we actually like negatitve gradient
  puts "#{i1}:#{p1} => #{i2}:#{p2} slope:#{(p2 - p1) / (i2 - i1).to_f} slope x irange: #{(p2 - p1) * (i1 + i2) / 2.0} sum:#{weighted_sum}"
end

#this blocks calcultes standart error of which reflects slope of sigmoid
center = weighted_sum
squerror_sum = 0
puts "center =  #{center}"
prob_by_rank.sort_by{|pair| pair[0]}.each_cons(2) do |pair1, pair2|
  i1, p1 = pair1
  i2, p2 = pair2
  # (i1-c)^2 + (i2-c)^2+ (i3-c)^2 +... =
  # i1^2 + i2^2 + i2^2  +...
  # - 2*i1*c - 2 * i2 * c - 2 * i3 * c + ...
  # + c*c + c*c + c*c +...
  squerror = sum_sqr_d(i1, i2) - (i1 + i2) * (i2 - i1) * center + (i2 - i1) * center * center
  slope = -(p2 - p1) / (i2 - i1).to_f
  squerror_sum += slope * squerror
end
puts "std_err = #{Math.sqrt(squerror_sum)}"
std_err = Math.sqrt(squerror_sum)
slope = -Math.sqrt(2)/(Math.sqrt(Math::PI)*std_err)

#debug block to Remove
translations = []
iter = 0
while translations.size < pick_size*pick_count and iter < 3 do
  translations +=
      Translation.joins(:word) # .left_outer_joins(:user_translation_learn_progresses)
      .joins("LEFT OUTER JOIN user_translation_learn_progresses \
         ON user_translation_learn_progresses.translation_id=translations.id \
         AND user_translation_learn_progresses.user_id=#{user.id}")
      .where(word:{dialect_id: target_dialect_id}, translation_dialect_id:source_dialect_id)
  #    .select('DISTINCT ON (word.spelling) *')
      .order(Arel.sql(
        "abs( COALESCE( \
        (1.0 - correct/(correct + failed + 0.01))*0.5^(0.1 * (#{maxpick} - last_counter)) \
        + (correct/(correct + failed + 0.01) - 0.5*(1 + tanh(#{slope}*(translations.rank-#{center}))) )*0.5^((#{maxpick} - last_counter)/#{learn_progress_count}) \
        ,0) + 0.5*(1 + tanh(#{slope}*(translations.rank-#{center}))) - 0.85) \
        + 0.02*RANDOM()"
        # "abs(0.5*(1 + tanh(#{slope}*(translations.rank-#{center}))) - 0.85)"
        )).drop(iter*(pick_size + 1) * (pick_count + 1)).take((pick_size + 1) * (pick_count + 1))
        .group_by{|t|t.word.spelling}.map{|s,ts|ts[0]}
  iter += 1
end

#---------------------------------------------------------------------------------------
#test display stuff block: remove it purely debug stuff
translations.sort_by{|trans| trans.rank}.each do |trans|
   sigmoid = 0.5*(1 + Math.tanh(slope*(trans.rank-center)))
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
   puts "[#{trans.rank}] #{trans.word.spelling} -> #{trans.translation}
   with probablityy = #{estimated_prob}; after #{iterations} iterations\
   from estimated_prob = #{estimated_prob} while sigmoid = #{sigmoid}; \
   recent_part = #{recent_part}; longer_part = #{longer_part}"
end
#---------------------------------------------------------------------------------------

# select translations for picks in sets
sets = []
taken = {"" => 0}
taken.default = 0
translations.take(pick_count).each{|trans|taken[trans]=1}
translations.take(pick_count).each do |trans|
  whole_word = trans.word.spelling
  puts "> > > [#{whole_word}] < < <"
  trans_set = []
  if whole_word.contains_kanji?
    puts ("#{whole_word} contains kanji")
    trans_set = []
    kanji_list = whole_word.each_char.select{|ch|ch.kanji?}
    reversed_kana_list = whole_word.reverse.each_char.select{|ch|ch.kana?}
    puts ("kanji_list #{kanji_list} reversed_kana_list #{reversed_kana_list}")
    trans_set = translations.sort_by do |t|
      same_kanji_cost = t.word.spelling.each_char.count{|ch|ch.in?(kanji_list)}*10
      taken_cost = (taken[t.word.spelling])
      kana_cost = - 2*reversed_kana_list.take(t.word.spelling.size).each_with_index.count{|ch,i| ch == t.word.spelling[-i-1]}
      same_word_cost = (t.word.spelling === whole_word ? 100 : 0)
      no_kana_cost = (reversed_kana_list.size === 0 ? 2*t.word.spelling.each_char.count{|ch|ch.kana?} : 0)
      size_dif = 0.05*(whole_word.size - t.word.spelling.size).abs
      same_kanji_cost + taken_cost + kana_cost + same_word_cost + no_kana_cost + 0.05*size_dif
    end.take(pick_size - 1)
  else
    puts ("#{whole_word} pure kana")
    trans_set = []
    trans_set = translations.sort_by do |t|
      kanji_cost = t.word.spelling.each_char.count{|ch|ch.contains_kanji?}*10
      taken_cost = (taken[t.word.spelling] )
      same_word_cost = (t.word.spelling === whole_word ? 100 : 0)
      start_same_cost = 2*t.word.spelling.each_char.to_a.each_with_index.count{|ch,i| ch === whole_word[i]}
      size_dif = 0.05*(whole_word.size - t.word.spelling.size).abs
      kanji_cost + taken_cost + same_word_cost + start_same_cost + size_dif
    end.take(pick_size - 1)
  end
  puts "good set complete is #{trans_set.map{|t|[t.word.spelling,t.translation]}}"
  trans_set.each{|t|taken[t.word.spelling]+=1}
  sets.append [trans,trans_set]
end


sets.each do |correct, translations|
  @pick_word_in_set = PickWordInSet.new
  japanese_dialect_id = source_dialect_id
  english_dialect_id = target_dialect_id
  @translations = translations
  @translations.append(correct)
  translations_ids = @translations.map{|t| t.id}
  # Find all WordSets that have the same words
  matching_translation_sets = TranslationSet.joins(:translations)
                              .where(translations: { id: translations_ids })
                              .group('translation_sets.id')
                              .having('COUNT(1) = ?', translations_ids.size)
  if matching_translation_sets.empty?
    # No matching WordSet found, so create a new one
    new_translation_set = TranslationSet.new
    new_translation_set.translations << @translations
    new_translation_set.save
    @translation_set = new_translation_set.reload
  else
    @translation_set = matching_translation_sets[0]
  end
  @correct = correct
  @pick_word_in_set.picked_id = nil
  @pick_word_in_set.correct_id = @correct.id
  @pick_word_in_set.translation_set = @translation_set
  @pick_word_in_set.version = 1
  @pick_word_in_set.user_id = current_user.id
  @saved = @pick_word_in_set.save
  @notice = "Pick word in set was successfully created."
end
