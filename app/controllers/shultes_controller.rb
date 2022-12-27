class ShultesController < ApplicationController
  before_action :set_shulte, only: %i[ show edit update destroy ]

  # GET /shultes or /shultes.json
  def index
    @shultes = Shulte.all
  end

  # GET /shultes/1 or /shultes/1.json
  def show
  end

  # GET /shultes/new
  def new
    @shulte = Shulte.new
  end

  # GET /shultes/1/edit
  def edit
  end

  # POST /shultes or /shultes.json
  def create
    @shulte = Shulte.new(shulte_params)

    respond_to do |format|
      if @shulte.save
        format.html { redirect_to shulte_url(@shulte), notice: "Shulte was successfully created." }
        format.json { render :show, status: :created, location: @shulte }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @shulte.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /shultes/1 or /shultes/1.json
  def update
    respond_to do |format|
      if @shulte.update(shulte_params)
        format.html { redirect_to shulte_url(@shulte), notice: "Shulte was successfully updated." }
        format.json { render :show, status: :ok, location: @shulte }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @shulte.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /shultes/1 or /shultes/1.json
  def destroy
    @shulte.destroy

    respond_to do |format|
      format.html { redirect_to shultes_url, notice: "Shulte was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_shulte
      @shulte = Shulte.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def shulte_params
      params.require(:shulte).permit(:user_id, :time, :mistakes, :size, :shuffle)
    end
end
