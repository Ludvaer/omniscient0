#  ActiveRecord::Base.logger = Logger.new(STDOUT)

def sum_sqr(i)
  i * (2 * i + 1) * (2 * i - 1) / 12.0
end
def sum_sqr_d(i1,i2)
  sum_sqr(i2) - sum_sqr(i1)
end

puts "#{1.5*1.5} = sum_sqr_d(1,2) = #{sum_sqr_d(1,2)}"
puts "#{2.5*2.5} = sum_sqr_d(1,3) = #{sum_sqr_d(2,3)}"
puts "#{1.5*1.5 + 2.5*2.5} = sum_sqr_d(1,3) = #{sum_sqr_d(1,3)}"
puts "#{2.5*2.5+3.5*3.5+4.5*4.5} = sum_sqr_d(2,5) = #{sum_sqr_d(1,3)}"

user = User.find_by(name: 'Lurr')
source_dialect_id = Dialect.find_by(name:'english').id
target_dialect_id =  Dialect.find_by(name:'japanese').id
puts "dialects ids are are #{source_dialect_id} => #{target_dialect_id}"
translations =
    Translation.joins(:word)
    .where('word.dialect_id':target_dialect_id, translation_dialect_id:source_dialect_id)
    .order(:priority)
min_priority = translations.map{|t| t.priority}.min
max_priority = translations.map{|t| t.priority}.max
counted_picks = 0
index = 0
last_index = 0
last_prob = 1
estimated_probs = { 0=>1.0, translations.size+1=>0.0  }
pick_index_by_id = {}
UserTranslationLearnProgress.delete_all
PickWordInSet
    .where("picked_id IS NOT NULL AND user_id=#{user.id}").order(:created_at)
    .each_with_index do |p,i|
        pick_index_by_id[p.id] = i
        is_correct = Translation.find_by(id:p.correct_id).word.spelling == Translation.find_by(id:p.picked_id).word.spelling
        t_ids = if p.correct_id == p.picked_id then [p.correct_id] else [ p.correct_id, p.picked_id] end
        t_ids.each do |t_id|
          lp = UserTranslationLearnProgress.find_by(user_id:user.id,translation_id: t_id)
          if lp.nil?
            lp = UserTranslationLearnProgress.new
            lp.correct = 0
            lp.failed = 0
            lp.user_id = user.id
            lp.translation_id = t_id
          end
          lp.last_counter = i
          if is_correct
            lp.correct += 1
          else
            lp.failed += 1
          end
          lp.save
        end
    end
maxi = pick_index_by_id.size
puts "pick_index_by_id of size #{maxi} is #{pick_index_by_id}"
translations.each do |translation|
  index = index + 1
  unless translation.rank == index
    translation.rank = index
    translation.save
  end
  picks = PickWordInSet
    .where("(correct_id = #{translation.id} OR picked_id = #{translation.id}) AND picked_id IS NOT NULL AND user_id=#{user.id}")
  correct_picks = picks.select{ |pick| Translation.find_by(id:pick.correct_id).word.spelling == Translation.find_by(id:pick.picked_id).word.spelling }
  estimated_prob = correct_picks.size / (picks.size.to_f + 1)
  if picks.exists?
    attempts_after = picks.map{|p|pick_index_by_id[p.id]}.max
    corrected_estimated_prob = 1.0 - attempts_after*0.1*(1.0 - estimated_prob)
    if attempts_after > 10
      corrected_estimated_prob = estimated_prob * (0.5**((attempts_after - 10.0)/1000.0))
    end
    estimated_prob = corrected_estimated_prob
    estimated_probs[index] = estimated_prob
    tpairs = picks.map{|pick| [Translation.find_by(id:pick.correct_id).word.spelling,Translation.find_by(id:pick.picked_id).word.spelling]}
    puts "#{index}:#{translation.priority}: [#{picks.map{|p|p.id}}]: #{tpairs}: #{estimated_prob}"
  end
  counted_picks = counted_picks + picks.size
end
puts "#{translations.size} translations are loaded starting from #{min_priority} to #{max_priority}"
puts "#{counted_picks} translations x picks counted"

weighted_sum, weight_sum = 0, 0
estimated_probs.sort_by{|pair| pair[0]}.each_cons(2) do |pair1, pair2|
  i1, p1 = pair1
  i2, p2 = pair2
  # slope = (p2 - p1) / (i2 - i1).to_f
  # weighted_sum += slope * (i1 + i2) * (i2 - i1) / 2.0 #kinda sum of slope*i for i from i1 to i2 (in midpoints)
  # weight_sum += slope * (i2 - i1).to_f #sum of slopes for each i
  weighted_sum -= (p2 - p1) * (i1 + i2) / 2.0 #we actually like negatitve gradient
  puts "#{i1}:#{p1} => #{i2}:#{p2} slope:#{(p2 - p1) / (i2 - i1).to_f} slope x irange: #{(p2 - p1) * (i1 + i2) / 2.0} sum:#{weighted_sum}"
end
center = weighted_sum
squerror_sum = 0
puts "center =  #{center}"
estimated_probs.sort_by{|pair| pair[0]}.each_cons(2) do |pair1, pair2|
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
