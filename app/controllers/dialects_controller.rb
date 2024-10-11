class DialectsController < ApplicationController
  before_action :set_dialect, only: %i[ show edit update destroy ]

  # GET /dialects or /dialects.json
  def index
    @dialects = Dialect.all
  end

  # GET /dialects/1 or /dialects/1.json
  def show
  end

  # GET /dialects/new
  def new
    @dialect = Dialect.new
  end

  # GET /dialects/1/edit
  def edit
  end

  # POST /dialects or /dialects.json
  def create
    @dialect = Dialect.new(dialect_params)

    respond_to do |format|
      if @dialect.save
        format.html { redirect_to dialect_url(@dialect), notice: "Dialect was successfully created." }
        format.json { render :show, status: :created, location: @dialect }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @dialect.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dialects/1 or /dialects/1.json
  def update
    respond_to do |format|
      if @dialect.update(dialect_params)
        format.html { redirect_to dialect_url(@dialect), notice: "Dialect was successfully updated." }
        format.json { render :show, status: :ok, location: @dialect }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @dialect.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dialects/1 or /dialects/1.json
  def destroy
    @dialect.destroy

    respond_to do |format|
      format.html { redirect_to dialects_url, notice: "Dialect was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dialect
      @dialect = Dialect.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def dialect_params
      params.require(:dialect).permit(:name, :language_id)
    end
end
