class TranslationSetsController < ApplicationController
  before_action :set_translation_set, only: %i[ show edit update destroy ]

  # GET /translation_sets or /translation_sets.json
  def index
    @translation_sets = TranslationSet.all
  end

  # GET /translation_sets/1 or /translation_sets/1.json
  def show
  end

  # GET /translation_sets/new
  def new
    @translation_set = TranslationSet.new
  end

  # GET /translation_sets/1/edit
  def edit
  end

  # POST /translation_sets or /translation_sets.json
  def create
    @translation_set = TranslationSet.new(translation_set_params)

    respond_to do |format|
      if @translation_set.save
        format.html { redirect_to translation_set_url(@translation_set), notice: "Translation set was successfully created." }
        format.json { render :show, status: :created, location: @translation_set }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @translation_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /translation_sets/1 or /translation_sets/1.json
  def update
    respond_to do |format|
      if @translation_set.update(translation_set_params)
        format.html { redirect_to translation_set_url(@translation_set), notice: "Translation set was successfully updated." }
        format.json { render :show, status: :ok, location: @translation_set }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @translation_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /translation_sets/1 or /translation_sets/1.json
  def destroy
    @translation_set.destroy

    respond_to do |format|
      format.html { redirect_to translation_sets_url, notice: "Translation set was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_translation_set
      @translation_set = TranslationSet.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def translation_set_params
      params.fetch(:translation_set, {})
    end
end
