class WordInSetsController < ApplicationController
  before_action :set_word_in_set, only: %i[ show edit update destroy ]

  # GET /word_in_sets or /word_in_sets.json
  def index
    @word_in_sets = WordInSet.all
  end

  # GET /word_in_sets/1 or /word_in_sets/1.json
  def show
  end

  # GET /word_in_sets/new
  def new
    @word_in_set = WordInSet.new
  end

  # GET /word_in_sets/1/edit
  def edit
  end

  # POST /word_in_sets or /word_in_sets.json
  def create
    @word_in_set = WordInSet.new(word_in_set_params)

    respond_to do |format|
      if @word_in_set.save
        format.html { redirect_to word_in_set_url(@word_in_set), notice: "Word in set was successfully created." }
        format.json { render :show, status: :created, location: @word_in_set }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @word_in_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /word_in_sets/1 or /word_in_sets/1.json
  def update
    respond_to do |format|
      if @word_in_set.update(word_in_set_params)
        format.html { redirect_to word_in_set_url(@word_in_set), notice: "Word in set was successfully updated." }
        format.json { render :show, status: :ok, location: @word_in_set }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @word_in_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /word_in_sets/1 or /word_in_sets/1.json
  def destroy
    @word_in_set.destroy

    respond_to do |format|
      format.html { redirect_to word_in_sets_url, notice: "Word in set was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_word_in_set
      @word_in_set = WordInSet.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def word_in_set_params
      params.require(:word_in_set).permit(:word_set_id, :word_id)
    end
end
