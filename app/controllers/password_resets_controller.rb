class PasswordResetsController < ApplicationController
  #get 'reset_request'  => 'password_resets#new'
  def new
  	init_request_form
  end

  #post 'send_reset_request'  => 'password_resets#create'
  def create
  	init_request_form
    @user =  @user.validate_email_input(user_params)
    err = @user.err
    if err
      p @user
      respond_to do |format|
        format.js { render :json => { :html => render_to_string('password_resets/_request_form'), redirect: false}, :content_type => 'text/json' }
        format.html { render :new }
      end
    else
      @user.send_password_reset_letter
      flash[:notice] = t('Password reset link sent')
      respond_to do |format|
        format.js { redirect_to login_url}
        format.html { redirect_to login_url }
      end
    end
  end

  #get password_resets/:token
  def edit
    init_reset_form
  end

  #patch reset_password
  def reset
    err = true
    if init_reset_form
      @user.validate_password_input(user_params)
      err = @user.err
      @success = @user.save()
      err |= !@success
    end
    if err
      respond_to do |format|
        format.js { render :json => { :html => render_to_string('_reset_form'), redirect: false}, :content_type => 'text/json' }
        format.html { render :edit }
      end
    else
      #@user.update_attribute(:password, user.password)
      #@user.update_attribute(:password, user.password_confirmation)
      @password_reset.destroy
      flash[:notice] = t('Password reset success.')
      respond_to do |format|
        format.js { render :json => { :html =>  redirect_link(login_url), redirect: true}, :content_type => 'text/json' }
        format.html { redirect_to login_url }
      end
    end
  end



  # GET /password_resets or /password_resets.json
  def index
    @password_resets = PasswordReset.all
  end

  # GET /password_resets/1 or /password_resets/1.json
  def show
  end


  # PATCH/PUT /password_resets/1 or /password_resets/1.json
  def update
    respond_to do |format|
      if @password_reset.update(password_reset_params)
        format.html { redirect_to password_reset_url(@password_reset), notice: "Password reset was successfully updated." }
        format.json { render :show, status: :ok, location: @password_reset }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @password_reset.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /password_resets/1 or /password_resets/1.json
  def destroy
    @password_reset.destroy

    respond_to do |format|
      format.html { redirect_to password_resets_url, notice: "Password reset was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    def init_request_form
      @user = User.new

    end

    def init_reset_form
      @token =params[:token]
      pr = PasswordReset.find_token(@token)
      @password_reset = pr
      if pr
        @salt = User.salt
        @user = User.find_by(id: pr.user_id)
        return true
      end
      false
    end

    def user_params
      params.require(:user).permit(:email,:password, :password_confirmation, :salt)
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_password_reset
      @password_reset = PasswordReset.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def password_reset_params
      params.require(:password_reset).permit(:user_id, :token)
    end
end
