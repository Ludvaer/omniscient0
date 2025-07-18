class PickWordInSetService
  PICK_SIZE = 9
  MAX_PICKS_PER_REQUEST =100
  TARGET_PROBABILITY = 0.85
  def initialize(params)
    @display_dialects = params[:display_dialects]
    @target_dialect = params[:target_dialect]
    @option_dialect = params[:option_dialect]
    @user = params[:current_user]
    @n = [[params[:n].to_i || 1, 1].max, 100].min
    @display_dialects_ids = @display_dialects.map{|d|d.id}
    @target_dialect_id = @target_dialect.id
    @option_dialect_id = @option_dialect.id
    #TODO: get rid of source_dialect using display dialects array now
    @source_dialect_id = (@display_dialects_ids + [@option_dialect_id])\
      .reject{|id|id==Dialect.find_by_name('kana').id || id == @target_dialect_id}[0]
    puts "PickWordInSetService #{@source_dialect_id}->#{@target_dialect_id} | #{@display_dialects_ids} ->#{ @option_dialect_id}"
    #TODO: seprate find and find or create
    @direction = PickWordInSetDirection.find_or_init(@target_dialect,@display_dialects,@option_dialect)
    @template = PickWordInSetTemplate.find_or_init(@direction, @user)
    puts ">>> @template.inspect: #{@template.inspect} direction:#{@template.direction} display:#{@template.direction.display_dialects.to_a.to_s}"
  end

  def self.create(params)
    PickWordInSetService.new(params).create
  end

  def new
    new_one = PickWordInSet.new
    new_one.template = @template
    new_one
  end

  def create
    @direction.save if @direction.new_record?
    @template.save if @template.new_record?
    incompelete = request_incomplete
    if incompelete.size < @n
      puts "incompelete.size < @n => #{incompelete.size} < #{@n}"
      incompelete += create_new_picks(@n,PICK_SIZE)
    else
      puts "incompelete.size > @n => #{incompelete.size} >= #{@n} return incomplete"
    end

    return incompelete
  end

  def template
    @template
  end

  def request_incomplete
    return @incomplete if @incomplete
    return [] if  @template.id.nil?
    @incomplete = PickWordInSet.joins( :template, correct: :word) \
      .includes( :template, correct: :word) \
      .where(picked_id: nil, template_id: @template.id).order(:created_at).to_a
    #.joins("INNER JOIN words ON words.id=correct.word_id")
    return @incomplete
  end


  def template_progress
    puts "checking new template_progress u: #{@user.id} dialects: #{@display_dialect_ids} => #{@option_dialect_id}"
    @TemplateProgress ||= TemplateProgress \
              .find_or_create_by!(template: @template)

  end

  def soft_logit(y, epsilon = 1e-15)
    y = [[y, epsilon].max, 1 - epsilon].min
    # Math.log((1 - y) / y)
    -Math.tan((y+ 0.5)*Math::PI)
  end

  def monotonic_fit(data)
    xs, ys = data.transpose

    # Sort y values descending, assign them to xs (already sorted)
    sorted_ys = ys.sort.reverse

    realigned_data = xs.zip(sorted_ys)

    return realigned_data
  end


  def estimate_sigmoid(y_by_x)
    y_by_x = monotonic_fit(y_by_x)
    s_w  = 0# ws.sum
    s_x  = 0# ws.zip(x_data).map { |w, x| w * x }.sum
    s_z  = 0#  ws.zip(zs).map     { |w, z| w * z }.sum
    s_xx = 0#  ws.zip(x_data).map { |w, x| w * x * x }.sum
    s_xz = 0#  ws.zip(x_data.zip(zs)).map { |w, (x, z)| w * x * z }.sum
    y_by_x.each_cons(2) do |(x1,y1),(x2,y2)|
      ss = (y2 - y1)/(x2-x1)
      if x1 == x2
        next
      end
      (x1..x2).each do |xx|
        x = xx
        y = y1 + (x-x1)*ss
        y = (y2-y1).abs > 1e-16 ? [y1,y2].min + (y - [y1,y2].min)**2/(y2-y1).abs : y
        z = soft_logit(y) #   Math.log((1 - y) / y) = ln(1-y) - ln (y)
        w =   1.0 / (1.0 + z**2)  # 1 / (1 +   Math.log**2((1 - y) / y))
        wxz = 1.0 / (z + 1.0 / z)
        s_w += w
        s_x += w * x
        s_z += wxz # w * z
        s_xx += w * x * x
        s_xz += wxz * x  # w * z * x
      end
    end
    denom = s_w * s_xx - s_x * s_x
    a = (s_w * s_xz - s_x * s_z) / denom
    c = (s_z - a * s_x) / s_w
    b = -c / a
    mean = -c / a
    slope = -a/Math::PI
    @center = mean
    @slope = slope
    return [mean, slope]
  end

  def guesstimate_sigmoid(y_by_x) # y_by_x = {[x1,y1], [x2, y2], .... [xk, yk]}
    y_by_x = monotonic_fit(y_by_x)
    # unless @center.nil? || @slope.nil?
    #   return [@center, @slope]
    # end
    # guesstimtes sigmoid (erf kind) while pretending that dy/dx is a normal distribution
    # sigmoid implied to be negatively sloped from 1 on left to 0 on right
    # !!! y values on range ends a supposed to be y[x_min] = 1 and y[x_max] = 0
    # otherwise we have infinitely wrong guestimate on tails which is kinda hard to minimize
    # average position weighted by -slope * dx where dx = segment length and slope = dy/dx
    # sum(-dy/dx*dx*avearge(x))/(sum(slope*dx))
    # which is sum(-dy*average(x))/sum(dy)
    # sum(dy) = y.last - y.first = 1
    # sum(-dy*average(x)) = sum(-(y2-y1)*(x2-x1)/2)
    #TODO: get rid of dict, supply sorted array of arrays [[x1,y1],[x2,y2],[x3,y3]]
    # .sort_by{|x,y| x} removed since supplied sorted
    sum, sqr_sum =  y_by_x.each_cons(2).inject([0, 0]) do |(acc, sqr_acc),((x1,y1),(x2,y2))|
      [acc +  -0.5 * (y2 - y1) * (x2 + x1), sqr_acc - ((y2 - y1 + 1) / (x2 - x1 + 1).to_f) * sum_sqr_d(x1, x2)]
    end

    puts "#{sum}, #{sqr_sum}"
    dispersion = [sqr_sum - sum * sum, 1].max
  #  puts "dispersion = #{sum * sum} - #{sqr_sum} = #{dispersion};  std_err = #{Math.sqrt(dispersion)}"
    center,std_err = sum, Math.sqrt(dispersion)
    slope = -Math.sqrt(2)/(Math.sqrt(Math::PI)*std_err) #we still like negative slope
  #  puts "center=#{center}; slope=#{slope})"
    @center = center
    @slope = slope
    [@center, @slope]
  end

  private
      def progresses
        @progresses ||= TemplateWordProgress \
          .eager_load(:word,:template) \
          .where(template: @template) \
          .order("words.rank")
        return @progresses
      end

      def get_estimated_prob_by_rank
        maxrank = Word.max_rank(@direction.target_dialect)
        learn_progress_count = progresses.size
        max_rank = 1
        maxpick = template_progress.counter
        puts "maxpick = #{maxpick}; learn_progress_count = #{learn_progress_count}"
        prob_by_rank = [[0,1.0]]
        sum = 1.0
        cnt = 1
        appended_value = 0
        progresses.each do |progress|
             rank = progress.word.rank
             correct = progress.correct || 0
             failed = progress.failed || 0
             # if rank > max_rank + 1
             #   prob_by_rank.append([max_rank + 1, [sum / cnt,appended_value].min])
             # end
             max_rank = [rank,max_rank].max
             estimated_prob =  (correct + 1e-15) / (correct + failed + 2e-15)
             short = (1 - estimated_prob) * (0.5**(0.1 * (maxpick - progress.last_counter)))
             long = (estimated_prob - 0)* (0.5**((maxpick - progress.last_counter)/learn_progress_count))
             appended_value = estimated_prob # *0.99 # + (short + long) * 0.01
             sum += appended_value
             cnt += 1
             prob_by_rank.append([rank, appended_value])
             puts "#rank = #{rank}; val = #{appended_value}   #{correct}/#{correct + failed} = #{estimated_prob} => \
              #{short} + #{long} = #{short + long}"
        end
        sum = prob_by_rank.sum{|x|x[1]};
        high = sum / prob_by_rank.length
        low = 0.1*sum / (maxrank + prob_by_rank.length)
        # prob_by_rank[1][1] = high
        prob_by_rank.append([maxpick+1, [low,appended_value].min])
        prob_by_rank.append([maxrank+1, 0])
        #puts "#{progresses.size} translation progresses counted"
        puts prob_by_rank.to_s
        prob_by_rank
      end

      #TODO: figure out how to organize math functions properly in some separte place
      def sum_sqr(i) # sum(a*a) for a from 0.5 to i - 0.5 (inclusive)
        i * (2 * i + 1) * (2 * i - 1) / 12.0
      end
      # sum_sqr(1) = 0.5*0.5 = 0.25
      # sum_sqr(2) = 0.5*0.5 + 1.5*1.5 = 2.5
      def sum_sqr_d(i1,i2) #sum(a*a) for a from i1 + 0.5 to i2 - 0.5 (inclusive)
        sum_sqr(i2) - sum_sqr(i1)
      end
      # puts "#{1.5*1.5} = sum_sqr_d(1,2) = #{sum_sqr_d(1,2)}"
      # puts "#{2.5*2.5} = sum_sqr_d(1,3) = #{sum_sqr_d(2,3)}"
      # puts "#{1.5*1.5 + 2.5*2.5} = sum_sqr_d(1,3) = #{sum_sqr_d(1,3)}"
      # puts "#{2.5*2.5 + 3.5*3.5 + 4.5*4.5} = sum_sqr_d(2,5) = #{sum_sqr_d(2,5)}"


      def get_translations_to_learn(minimal_size)
        maxrank = Word.max_rank(@direction.target_dialect)
        margin = minimal_size/10+5
        center,slope = estimate_sigmoid(get_estimated_prob_by_rank)
        puts "center=#{center}; slope=#{slope})"
        if center < 0
          slope = 1 / (1 / slope + center)
          center = 0
          slope = [-1.0 / Math.sqrt(maxrank), slope].min
        end
        if slope < - 0.05 #if comeone managed to archieve sharp transition from new to old
          slope = -0.05 # blur the slope to include new translations
          center += 0.5*(20 + 1/slope) # move center to new translations
        end
        slope = [-1.0 /(maxrank), slope].min
        puts "center=#{center}; slope=#{slope})"
        maxpick = template_progress.counter
        learn_progress_count = progresses.size
        translations = []
        prob_from_sigmoid =  "0.5*(1 + tanh((#{slope})*(words.rank-(#{center}))))"
        naive_prob = "((correct + 0.1)/(correct + failed + 0.2))"
        #not really probb but additiona decaying prob over sigmoid
        prob_from_progress = \
            "(1.0 - #{naive_prob})*0.5^(0.2 * (#{maxpick} - last_counter)) \
            + (#{naive_prob} - #{prob_from_sigmoid})*0.5^((#{maxpick} - last_counter)/#{learn_progress_count})"
        #also sorry we guesstimated erf bur will use tanh instead
        incompelete = request_incomplete
        excluded_word_ids = incompelete.pluck('correct.word_id').uniq
        #request to exclude all words from sets in incomplete picks:
        #excluded_word_ids = @incompelete.joins(translation_set: :translations).pluck('translations.word_id').uniq
        puts "incompelete: #{incompelete.map {|p|p.id }} excluded_word_ids #{excluded_word_ids}"
        dialects_of_interest = @display_dialects_ids + [@option_dialect_id]
        # translations =
        #     Translation.joins(:word) \
        #     .includes(:word) \
        #     .joins("LEFT OUTER JOIN template_word_progresses \
        #        ON template_word_progresses.template_id=#{@template.id} \
        #        AND template_word_progresses.word_id=word.id") \
        #     .where(word:{dialect_id: @target_dialect_id}, translation_dialect_id: @source_dialect_id) \
        #     .where.not(word_id: excluded_word_ids)\
        #     .order(Arel.sql( \
        #       "COALESCE((#{prob_from_progress}) * (#{prob_from_sigmoid}) ,0) \
        #       + abs(#{prob_from_sigmoid} - #{TARGET_PROBABILITY}) \
        #       + 0.000000001*RANDOM()" \
        #       )).select('DISTINCT ON (word.id) translations.*')
        #       .take(minimal_size + margin) #TODO: remake this to select word and then proper trnaslation for each
        words = Word.joins("LEFT OUTER JOIN template_word_progresses \
               ON template_word_progresses.template_id=#{@template.id} \
               AND template_word_progresses.word_id=words.id") \
            .where(dialect_id: @target_dialect_id) \
            .where.not(id: excluded_word_ids)\
            .order(Arel.sql( \
              "COALESCE((#{prob_from_progress}) * (#{prob_from_sigmoid}) ,0) \
              + abs(#{prob_from_sigmoid} - #{TARGET_PROBABILITY}) \
              + 0.000000001*RANDOM()" \
              )).take(minimal_size + margin)
        translations = Translation.eager_load(:word)\
              .where(word:{id: words.pluck(:id)}, translation_dialect_id: @source_dialect_id)
              .order(word: {id: :asc}, rank: :asc)
              .select('DISTINCT ON (word.id) translations.*') #TODO: use left inner join
        info = translations.map do |t|
          probfromsigmoid =  0.5*(1 + Math.tanh((slope)*(t.rank-(center))))
          [t.rank, t.word.spelling, t.translation, probfromsigmoid].to_s
        end
        puts info
        translations
      end

      def group_tranlation_sets(translations, pick_count, pick_size)
        # select translations for picks in sets
        sets = []
        taken = {"" => 0}
        taken.default = 0
        # picked_translations = translations.take(pick_count)
        # picked_translations.each{|trans|taken[trans]=1}
        translations.each do |trans|
          if taken[trans.word.spelling] > 0
            next
          end
          if sets.size >= pick_count
            break
          end
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
              size_dif = 0.01*(whole_word.size - t.word.spelling.size).abs
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
              size_dif = 0.01*(whole_word.size - t.word.spelling.size).abs
              kanji_cost + taken_cost + same_word_cost + start_same_cost + size_dif
            end.take(pick_size - 1)
          end
          puts "good set complete is #{trans_set.map{|t|[t.word.spelling,t.translation]}}"
          trans_set.each{|t|taken[t.word.spelling]+=1}
          sets.append [trans,trans_set]
        end
        sets
      end

      def save_translation_groups_as_picks(sets)
        source_language_id = Dialect.find_by(id: @source_dialect_id).language_id
        target_language_id = Dialect.find_by(id: @target_dialect_id).language_id
        languages = [source_language_id, target_language_id]
        #other_dialect_ids = Dialect.where(language_id:languages).pluck(:id).reject{|id|id==@source_dialect_id}
        other_dialect_ids =(@display_dialects_ids + [@option_dialect_id]).reject{|id|id==@source_dialect_id}
        picks = []
        sets.each do |correct, translations|
          pick_word_in_set = PickWordInSet.new
          @translations = translations
          @translations.append(correct)
          @translations.sort_by!{|t|t.id}
          word_ids = @translations.map{|t|t.word.id}
          other_relevant_translations = Translation.joins(:word).where(word:{id: word_ids}, translation_dialect_id:other_dialect_ids)
          @translations += other_relevant_translations
          translations_ids = @translations.map{|t| t.id}
          # Find all WordSets that have the same words
          matching_translation_sets = TranslationSet.joins(:translations)
                                      .where(translations: { id: translations_ids })
                                      .group('translation_sets.id')
                                      .having('COUNT(1) = ?', translations_ids.size)
          if matching_translation_sets.empty?
            # No matching WordSet found, so create a new one
            new_translation_set = TranslationSet.create!
            # TranslationSetTranslation.import(
            #   translations_ids.map { |t_id| { translation_set_id: new_translation_set.id, translation_id: t_id } },
            # )
            values = translations_ids.map { |t_id| "(#{new_translation_set.id}, #{t_id})" }.join(", ")
            sql = "INSERT INTO translation_sets_translations (translation_set_id, translation_id) VALUES #{values}"
            # Execute the SQL
            ActiveRecord::Base.connection.execute(sql)
            @translation_set = new_translation_set
          else
            @translation_set = matching_translation_sets[0]
          end
          pick_word_in_set.picked_id = nil
          pick_word_in_set.correct_id = correct.id
          pick_word_in_set.translation_set_id = @translation_set.id
          pick_word_in_set.version = 1
          pick_word_in_set.user_id = @user.id
          pick_word_in_set.option_dialect_id = @option_dialect_id
          pick_word_in_set.template_id = @template.id
          puts "saving pick_word_in_set = #{pick_word_in_set.attributes};"
          @saved = pick_word_in_set.save
          puts "pick_word_in_set id = #{pick_word_in_set.id}; saved = #{@saved} / #{pick_word_in_set.errors}"
          picks.append(pick_word_in_set)
        end
        picks
      end

      def create_new_picks(pick_count, pick_size)
        translations = get_translations_to_learn(pick_count * pick_size + 5)
        sets = group_tranlation_sets(translations, pick_count, pick_size)
        picks = save_translation_groups_as_picks(sets)
        picks
      end
end
