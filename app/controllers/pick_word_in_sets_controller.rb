class PickWordInSetsController < ApplicationController
  before_action :set_user
  before_action :set_pick_word_in_set, only: %i[ show edit update destroy ]

  # GET /pick_word_in_sets or /pick_word_in_sets.json
  def index
    @pick_word_in_sets = PickWordInSet.where(user_id: @user.id)
  end

  # GET /pick_word_in_sets/1 or /pick_word_in_sets/1.json
  def show
    @n = params[:n] || 1
    service = PickWordInSetService.new(@params_as_objects)
    @incompelete = service.request_incomplete
    puts("@incompelete[#{@incompelete.size}]")
  end

  # display testing start page with already existing tests if they existing
  # and button to create action for making more
  # GET /pick_word_in_sets/new
  def new
    @n = params[:n]
    @target_dialect_name = params[:target]
    @option_dialect_name = params[:option]
    @display_dialect_names = params[:display]
    @display_dialect_names = case @display_dialect_names
                            when String
                              @display_dialect_names.split(",") # if comma-separated string
                            when Array
                              @display_dialect_names
                            else
                              []
                            end
    params_as_objects = {
        display_dialects: @display_dialect_names.map{|name|Dialect.find_by_name(name)},
        target_dialect: Dialect.find_by_name(@target_dialect_name),
        option_dialect: Dialect.find_by_name(@option_dialect_name),
        current_user: @user,
        n: @n
      }
    @display_dialects_ids = @display_dialect_names.map{|name|Dialect.find_by_name(name).id}
    @target_dialect_id = Dialect.find_by_name(@target_dialect_name).id
    @option_dialect_id = Dialect.find_by_name(@option_dialect_name).id
    puts "--params_as_objects--"
    puts params_as_objects.to_s
    service = PickWordInSetService.new(params_as_objects)
    @incompelete = service.request_incomplete
    puts ("@incompelete[#{@incompelete.size}]")
    @pick_word_in_set = service.new
    puts "#{@pick_word_in_set.template.inspect}"
    puts "#{@pick_word_in_set.template.direction.inspect}"
  end

  # open already existing test to wiev or pass
  # GET /pick_word_in_sets/1/edit
  def edit
    @n = params[:n] || 1
    @incompelete = PickWordInSet.where(picked_id: nil, user_id: @user.id).order(:created_at)
    puts("@incompelete[#{@incompelete.size}]")
  end

  # creates and displays new test with undefined user answer
  # POST /pick_word_in_sets or /pick_word_in_sets.json
  def create
    @n = params[:n]
    @target_dialect_name = params[:target]
    @option_dialect_name = params[:option]
    @display_dialect_names = params[:display]
    @display_dialect_names = case @display_dialect_names
                            when String
                              @display_dialect_names.split(",") # if comma-separated string
                            when Array
                              @display_dialect_names
                            else
                              []
                            end
    params_as_objects = {
        display_dialects: @display_dialect_names.map{|name|Dialect.find_by_name(name)},
        target_dialect: Dialect.find_by_name(@target_dialect_name),
        option_dialect: Dialect.find_by_name(@option_dialect_name),
        current_user: @user,
        n: @n
      }
    puts "--params_as_objects--"
    puts params_as_objects.to_s
    @display_dialects_ids = @display_dialect_names.map{|name|Dialect.find_by_name(name).id}
    @target_dialect_id = Dialect.find_by_name(@target_dialect_name).id
    @option_dialect_id = Dialect.find_by_name(@option_dialect_name).id
    @recursive = ( params[:recursive] == 'false') ? false : params[:recursive] || false
    service = PickWordInSetService.new(params_as_objects)
    @pick_word_in_sets = service.create
    @pick_word_in_set = @pick_word_in_sets[0]
    respond_to do |format|
      unless @pick_word_in_set.new_record?
        format.html { redirect_to edit_pick_word_in_set_url(@pick_word_in_set), notice: @notice}
        format.json { render json:  {\
           data: DataPreloadService.fetch_data({"PickWordInSet" => [@pick_word_in_sets.pluck(:id)]}, recursive: @recursive), \
           template_id: service.template.id
           }, status: :created, location: @pick_word_in_set }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @pick_word_in_set.errors, status: :unprocessable_entity }
      end
    end
  end

  #represents solving test by setting selected by user field
  # PATCH/PUT /pick_word_in_sets/1 or /pick_word_in_sets/1.json
  def update
    service = PickWordInSetService.new(@params_as_objects)
    template = service.template
    template_progress = service.template_progress
    puts "template_progress=#{template_progress} counter=#{template_progress.counter}"
    respond_to do |format|
      # @picked = @translations.find{|t| t.id == pick_word_in_set_params[:picked_id].to_i}
      picked_id = pick_word_in_set_params[:picked_id].to_i
      @picked = picked_id == 0 ? Translation.find_by(id:picked_id) : @translations.find{|t| t.id == picked_id}
      if (@pick_word_in_set.picked_id == nil and \
          not @picked.nil?  and \
          @pick_word_in_set.user_id == @user_id)
        target_dialect_id = @correct.word.dialect_id
        source_dialect_id = @correct.translation_dialect_id
        template_progress.increment!(:counter)
        puts "update template_progress=#{template_progress.inspect} counter=#{template_progress.counter}"
        [@correct, @picked].uniq.each do |translation|
          utlp = TemplateWordProgress.find_or_create_by!(word: translation.word, template: template)
          last_counter = [template_progress.counter || 0, utlp.last_counter || 0].max
          if @correct.word.spelling === @picked.word.spelling
            utlp.update!(correct: ((utlp.correct || 0) + 1), last_counter: last_counter)
          else
            utlp.update!(failed: ((utlp.failed || 0) + 1), last_counter: last_counter)
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
      @n = params[:n]
      @pick_word_in_set = PickWordInSet \
      .joins(:translation_set, translation_set: [:translations], translation_set: {translations: :word}, template: :direction ) \
      .includes(:translation_set, translation_set: [:translations], translation_set: {translations: :word}, template: :direction) \
      .find(params[:id])
      @translation_set = @pick_word_in_set.translation_set
      @translations = @translation_set.translations
      @correct = @translations.find{|t| t.id == @pick_word_in_set.correct_id}
      @target_dialect_id = @correct.word.dialect_id
      @source_dialect_id = @correct.translation_dialect_id
      @option_dialect_id = @pick_word_in_set.option_dialect_id
      @template = @pick_word_in_set.template
      @direction = @template.direction
      @params_as_objects = {
          display_dialects: @direction.display_dialects,
          target_dialect: @direction.target_dialect,
          option_dialect: @direction.option_dialect,
          current_user: @user,
          n: @n
        }
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
