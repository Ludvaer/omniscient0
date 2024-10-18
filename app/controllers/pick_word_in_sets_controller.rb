class PickWordInSetsController < ApplicationController
  before_action :set_pick_word_in_set, only: %i[ show edit update destroy ]

  # GET /pick_word_in_sets or /pick_word_in_sets.json
  def index
    @pick_word_in_sets = PickWordInSet.all
  end

  # GET /pick_word_in_sets/1 or /pick_word_in_sets/1.json
  def show
  end

  # I need move this logic to create and make start test button here or smth
  # GET /pick_word_in_sets/new
  def new
    incompelete = PickWordInSet.where(picked_id: nil).order(:created_at)
    if incompelete.empty?
      @pick_word_in_set = PickWordInSet.new
      japanese_dialect_id = Dialect.find_by(name:'japanese').id
      english_dialect_id = Dialect.find_by(name:'english').id
      @translations = Translation.joins(:word).where('word.dialect_id':japanese_dialect_id, translation_dialect_id:english_dialect_id)
          .order('RANDOM()').take(5)
      translations_ids = @translations.map{|t| t.id}
      # Find all WordSets that have at least the same words
      matching_translation_sets = TranslationSet.joins(:translations)
                                  .where(translations: { id: translations_ids })
                                  .group('translation_sets.id')
                                  .having('COUNT(1) = ?', translations_ids.size)
      if matching_translation_sets.empty?
        # No matching WordSet found, so create a new one
        new_translation_set = TranslationSet.create!
        new_translation_set.translations << @translations
        new_translation_set.save
        @translation_set = new_translation_set.reload
      else
        @translation_set = matching_translation_sets[0]
      end
      @correct = @translations[0]
      @pick_word_in_set.picked_id = nil
      @pick_word_in_set.correct_id = @correct.id
      @pick_word_in_set.translation_set = @translation_set
      @pick_word_in_set.version = 1
      @pick_word_in_set.save
    else
      @pick_word_in_set = incompelete[0]
      @translation_set = @pick_word_in_set.translation_set
      @translations = @translation_set.translations
      @correct = @translations.find{|t| t.id == @pick_word_in_set.correct_id}
    end
  end

  # GET /pick_word_in_sets/1/edit
  def edit
  end

  #i need to move here logic currently in new and move this to
  # POST /pick_word_in_sets or /pick_word_in_sets.json
  def create
    @pick_word_in_set = PickWordInSet.find_by(correct: pick_word_in_set_params.correct)

    respond_to do |format|
      if @pick_word_in_set.save
        format.html { redirect_to pick_word_in_set_url(@pick_word_in_set), notice: "Pick word in set was successfully created." }
        format.json { render :show, status: :created, location: @pick_word_in_set }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @pick_word_in_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pick_word_in_sets/1 or /pick_word_in_sets/1.json
  def update
    respond_to do |format|
      if @pick_word_in_set.update(pick_word_in_set_params)
        format.html { redirect_to pick_word_in_set_url(@pick_word_in_set), notice: "Pick word in set was successfully updated." }
        format.json { render :show, status: :ok, location: @pick_word_in_set }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @pick_word_in_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pick_word_in_sets/1 or /pick_word_in_sets/1.json
  def destroy
    @pick_word_in_set.destroy

    respond_to do |format|
      format.html { redirect_to pick_word_in_sets_url, notice: "Pick word in set was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pick_word_in_set
      @pick_word_in_set = PickWordInSet.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def pick_word_in_set_params
      params.require(:pick_word_in_set).permit(:correct_id, :picked_id, :set_id, :version)
    end
end
