class PickWordInSetsController < ApplicationController
  before_action :set_pick_word_in_set, only: %i[ show edit update destroy ]
  before_action :set_user

  # GET /pick_word_in_sets or /pick_word_in_sets.json
  def index
    @pick_word_in_sets = PickWordInSet.where(user_id: @user.id)
  end

  # GET /pick_word_in_sets/1 or /pick_word_in_sets/1.json
  def show
    @n = params[:n] || 1
    params[:current_user] = @user
    params[:target_dialect_id] = @target_dialect_id
    params[:source_dialect_id] = @source_dialect_id
    params[:option_dialect_id] = @option_dialect_id
    service = PickWordInSetService.new(params)
    @incompelete = service.request_incomplete
    puts("@incompelete[#{@incompelete.size}]")
  end

  # I need move this logic to create and make start test button here or smth
  # GET /pick_word_in_sets/new
  def new
    @n = params[:n]
    @source_dialect_id = params[:source_dialect_id]
    @target_dialect_id = params[:target_dialect_id]
    @option_dialect_id = params[:option_dialect_id]
    service = PickWordInSetService.new(params.merge(current_user: @user))
    @incompelete = service.request_incomplete
    puts("@incompelete[#{@incompelete.size}]")
    @pick_word_in_set = PickWordInSet.new
  end

  # GET /pick_word_in_sets/1/edit
  def edit
    @n = params[:n] || 1
    @incompelete = PickWordInSet.where(picked_id: nil, user_id: @user.id).order(:created_at)
    puts("@incompelete[#{@incompelete.size}]")
  end

  # POST /pick_word_in_sets or /pick_word_in_sets.json
  def create
    service = PickWordInSetService.new(params)
    @recursive = params[:recursive] || false
    if (@recursive == 'false')
      @recursive = false
    end
    @pick_word_in_sets = PickWordInSet.create(params.merge(current_user: @user))
    @pick_word_in_set = @pick_word_in_sets[0]
    respond_to do |format|
      unless @pick_word_in_set.new_record?
        format.html { redirect_to edit_pick_word_in_set_url(@pick_word_in_set), notice: @notice}
        format.json { render json: \
           DataPreloadService.fetch_data({"PickWordInSet" => [@pick_word_in_sets.pluck(:id)]}, recursive: @recursive) \
           , status: :created, location: @pick_word_in_set }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @pick_word_in_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pick_word_in_sets/1 or /pick_word_in_sets/1.json
  def update
    params[:target_dialect_id] = @target_dialect_id
    params[:source_dialect_id] = @source_dialect_id
    params[:option_dialect_id] = @option_dialect_id
    service = PickWordInSetService.new(params.merge(current_user: @user))
    dialect_progress = service.dialect_progress
    puts "dialect_progress=#{dialect_progress} counter=#{dialect_progress.counter}"
    respond_to do |format|
      # @picked = @translations.find{|t| t.id == pick_word_in_set_params[:picked_id].to_i}
      picked_id = pick_word_in_set_params[:picked_id].to_i
      @picked = picked_id == 0 ? Translation.find_by(id:picked_id) : @translations.find{|t| t.id == picked_id}
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
      @option_dialect_id = @pick_word_in_set.option_dialect_id
    end

    def set_user
      @user = current_user
      @user_id = @user.id.to_i
    end



    # Only allow a list of trusted parameters through.
    def pick_word_in_set_params
      params.require(:pick_word_in_set).permit(:picked_id, :n, :source_dialect_id, :target_dialect_id, :option_dialect_id)
    end

end
