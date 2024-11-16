class PickWordInSetsController < ApplicationController
  before_action :set_pick_word_in_set, only: %i[ show edit update destroy ]
  before_action :set_user
  PICK_SIZE = 9
  MAX_PICKS_PER_REQUEST =100
  TARGET_PROBABILITY = 0.85

  # GET /pick_word_in_sets or /pick_word_in_sets.json
  def index
    @pick_word_in_sets = PickWordInSet.where(user_id: @user.id)
  end

  # GET /pick_word_in_sets/1 or /pick_word_in_sets/1.json
  def show
    @incompelete = PickWordInSet.where(picked_id: nil, user_id: @user.id).order(:created_at)
    puts("@incompelete[#{@incompelete.size}]")
  end

  # I need move this logic to create and make start test button here or smth
  # GET /pick_word_in_sets/new
  def new
    @incompelete = PickWordInSet.where(picked_id: nil, user_id: @user.id).order(:created_at)
    puts("@incompelete[#{@incompelete.size}]")
    @pick_word_in_set = PickWordInSet.new
  end

  # GET /pick_word_in_sets/1/edit
  def edit
    @incompelete = PickWordInSet.where(picked_id: nil, user_id: @user.id).order(:created_at)
    puts("@incompelete[#{@incompelete.size}]")
  end

  # POST /pick_word_in_sets or /pick_word_in_sets.json
  def create
    @target_dialect_id ||= Dialect.find_by(name:'japanese').id
    @source_dialect_id ||= Dialect.find_by(name:'english').id
    @target_dialect_ids ||= [Dialect.find_by(name:'japanese').id]
    @source_dialect_ids ||= [Dialect.find_by(name:'english').id]
    puts "dialect_progress=#{dialect_progress} counter=#{dialect_progress.counter}"
    n = [params[:n].to_i || 1, 1].max
    puts "n1 = #{n}"
    n = [n, MAX_PICKS_PER_REQUEST].min
    puts "n2 = #{n}"
    incompelete = PickWordInSet.where(picked_id: nil, user_id: @user.id).order(:created_at)
    @incompelete = incompelete
    if incompelete.size < n
      puts "incompelete.size < n => #{incompelete.size} < #{n}"
      incompelete += create_new_picks(n,PICK_SIZE)
    end
    @pick_word_in_set = incompelete[0]
    @notice = "Incomplete pick word in set."
    @saved = true

    puts(">>> rendering #{@pick_word_in_set} #{@pick_word_in_set.attributes}")
    if n <= 1
      respond_to do |format|
        if @saved
          format.html { redirect_to edit_pick_word_in_set_url(@pick_word_in_set), notice: @notice}
          format.json { render :show, status: :created, location: @pick_word_in_set }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @pick_word_in_set.errors, status: :unprocessable_entity }
        end
      end
    else
      @pick_word_in_sets = incompelete
      puts ("@pick_word_in_set.id #{@pick_word_in_set.id}")
      respond_to do |format|
        if @saved
          format.html { redirect_to edit_pick_word_in_set_url(@pick_word_in_set), notice: @notice}
          format.json { render json: \
             DataPreloadService.fetch_data({"PickWordInSet" => [@pick_word_in_sets.pluck(:id)]}, recursive: false) \
             , status: :created, location: @pick_word_in_set }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @pick_word_in_set.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /pick_word_in_sets/1 or /pick_word_in_sets/1.json
  def update
    @target_dialect_id = @correct.word.dialect_id
    @source_dialect_id = @correct.translation_dialect_id
    puts "dialect_progress=#{dialect_progress} counter=#{dialect_progress.counter}"
    respond_to do |format|
      @picked = @translations.find{|t| t.id == pick_word_in_set_params[:picked_id].to_i}
      if (@pick_word_in_set.picked_id == nil and \
          not @picked.nil?  and \
          @pick_word_in_set.user_id == @user_id)
        target_dialect_id = @correct.word.dialect_id
        source_dialect_id = @correct.translation_dialect_id
        dialect_progress.increment!(:counter)
        puts "update dialect_progress=#{dialect_progress} counter=#{dialect_progress.counter}"
        [@correct.id, @picked.id].uniq.each do |trans_id|
          utlp = UserTranslationLearnProgress.find_or_create_by!(translation_id: trans_id, user_id: @user_id)
          last_counter = [dialect_progress.counter, utlp.last_counter].max
          if @correct.word.spelling === @picked.word.spelling
            utlp.update!(correct: (utlp.correct + 1), last_counter: last_counter)
          else
            utlp.update!(failed: (utlp.failed + 1), last_counter: last_counter)
          end
        end
        @pick_word_in_set.update!(picked_id: pick_word_in_set_params[:picked_id].to_i)
        format.html { redirect_to pick_word_in_set_url(@pick_word_in_set), notice: "Pick word in set was successfully updated." }
        format.json { render :show, status: :ok, location: @pick_word_in_set }
      else
        flash[:notice] = t('Something wrong')
        format.html { render :edit, status: :unprocessable_entity, notice: "Something wrong." }
        format.json { render json: @pick_word_in_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pick_word_in_sets/1 or /pick_word_in_sets/1.json
  def destroy
    # @pick_word_in_set.destroy
    respond_to do |format|
      format.html { redirect_to pick_word_in_sets_url, notice: "No deleting please." }
      format.json { render :show, status: :unprocessable_entity }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pick_word_in_set
      @pick_word_in_set = PickWordInSet \
      .joins(:translation_set, translation_set: [:translations], translation_set: {translations: :word}) \
      .includes(:translation_set, translation_set: [:translations], translation_set: {translations: :word}) \
      .find(params[:id])
      @translation_set = @pick_word_in_set.translation_set
      @translations = @translation_set.translations
      @correct = @translations.find{|t| t.id == @pick_word_in_set.correct_id}
      @target_dialect_id = @correct.word.dialect_id
      @source_dialect_id = @correct.translation_dialect_id
    end

    def set_user
      @user = current_user
      @user_id = @user.id.to_i
    end

    # Only allow a list of trusted parameters through.
    def pick_word_in_set_params
      params.require(:pick_word_in_set).permit(:picked_id, :n)
    end

    def dialect_progress
      puts "checking new dialect_progress u: #{@user.id} dialects: #{@source_dialect_id} => #{@target_dialect_id}"
      @dialect_progress ||= UserDialectProgress \
                .find_or_create_by!(source_dialect_id: @source_dialect_id, \
                                   dialect_id: @target_dialect_id, \
                                   user_id: @user.id)
    end

    def progresses
      @progresses ||= UserTranslationLearnProgress \
        .includes(:translation) \
        .joins("INNER JOIN translations ON translations.id=user_translation_learn_progresses.translation_id") \
        .joins("INNER JOIN words ON words.id=translations.word_id") \
        .where("user_translation_learn_progresses.user_id = #{@user.id} \
           AND translations.translation_dialect_id IN (?) \
           AND words.dialect_id IN (?)", @source_dialect_id, @target_dialect_id) \
        .order("translations.rank")
      return @progresses
    end

    def get_estimated_prob_by_rank
      prob_by_rank = [[0, 1.0]]
      learn_progress_count = progresses.size
      max_rank = 1
      maxpick = dialect_progress.counter
      puts "maxpick = #{maxpick}; learn_progress_count = #{learn_progress_count}"
      progresses.each do |progress|
           rank = progress.translation.rank
           max_rank = [rank,max_rank].max
           estimated_prob =  progress.correct / (progress.correct + progress.failed + 0.01)
           short = (1 - estimated_prob) * (0.5**(0.1 * (maxpick - progress.last_counter)))
           long = (estimated_prob - 0)* (0.5**((maxpick - progress.last_counter)/learn_progress_count))
           prob_by_rank.append([rank, short + long])
           puts "#rank = #{rank}; #{progress.correct}/#{progress.correct + progress.failed} = #{estimated_prob} => \
            #{short} + #{long} = #{short + long}"
      end
      prob_by_rank.append([max_rank+1, 0])
      #puts "#{progresses.size} translation progresses counted"
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

    def guesstimate_sigmoid(y_by_x) # y_by_x = {[x1,y1], [x2, y2], .... [xk, yk]}
      unless @center.nil? || @slope.nil?
        return [@center, @slope]
      end
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
        [acc +  -0.5 * (y2 - y1) * (x2 + x1), sqr_acc - ((y2 - y1) / (x2 - x1).to_f) * sum_sqr_d(x1, x2)]
      end
      dispersion = [sqr_sum - sum * sum, 1].max
      puts "dispersion = #{sum * sum} - #{sqr_sum} = #{dispersion};  std_err = #{Math.sqrt(dispersion)}"
      center,std_err = sum, Math.sqrt(dispersion)
      slope = -Math.sqrt(2)/(Math.sqrt(Math::PI)*std_err) #we still like negative slope
      puts "center=#{center}; slope=#{slope})"
      @center = center
      @slope = slope
      [@center, @slope]
    end

    def get_translations_to_learn(minimal_size)
      margin = minimal_size/10+5
      center,slope = guesstimate_sigmoid(get_estimated_prob_by_rank)
      if slope < - 0.1 #if comeone managed to archieve sharp transition from new to old
        slope = -0.1 # blur the slope to include new translations
        center += 0.5*(10 + 1/slope) # move center to new translations
      end
      maxpick = dialect_progress.counter
      learn_progress_count = progresses.size
      translations = []
      #a lso sorry we guesstimated erf bur will use tanh instead
      translations =
          Translation.joins(:word) \
          .includes(:word) \
          .joins("LEFT OUTER JOIN user_translation_learn_progresses \
             ON user_translation_learn_progresses.translation_id=translations.id \
             AND user_translation_learn_progresses.user_id=#{@user.id}") \
          .where(word:{dialect_id: @target_dialect_id}, translation_dialect_id: @source_dialect_id) \
      #   .select('DISTINCT ON (word.spelling) *') #sadly does not work if not sorted primarily by spelling
          .order(Arel.sql( \
            "abs( COALESCE( \
            (1.0 - correct/(correct + failed + 0.01))*0.5^(0.1 * (#{maxpick} - last_counter)) \
            + (correct/(correct + failed + 0.01) - 0.5*(1 + tanh(#{slope}*(translations.rank-#{center}))) )*0.5^((#{maxpick} - last_counter)/#{learn_progress_count}) \
            ,0) + 0.5*(1 + tanh(#{slope}*(translations.rank-#{center}))) - 0.85) \
            + 0.02*RANDOM()" \
            )).take(minimal_size + margin)
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
      sets
    end

    def save_translation_groups_as_picks(sets)
      picks = []
      sets.each do |correct, translations|
        @pick_word_in_set = PickWordInSet.new
        @translations = translations
        @translations.append(correct)
        @translations.sort_by!{|t|t.id}
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
        @correct = correct
        @pick_word_in_set.picked_id = nil
        @pick_word_in_set.correct_id = @correct.id
        @pick_word_in_set.translation_set_id = @translation_set.id
        @pick_word_in_set.version = 1
        @pick_word_in_set.user_id = @user.id

        puts "saving @pick_word_in_set = #{@pick_word_in_set.attributes};"
        @saved = @pick_word_in_set.save
        puts "@pick_word_in_set id = #{@pick_word_in_set.id}; saved = #{@saved} / #{@pick_word_in_set.errors}"
        picks.append(@pick_word_in_set)
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
