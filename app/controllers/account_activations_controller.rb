class AccountActivationsController < ApplicationController

  # GET /account_activations or /account_activations.json
  def index
    @account_activations = AccountActivation.all
  end

  # GET /account_activations/1 or /account_activations/1.json
#  def show
#  end

  # GET /account_activations/new
  def new
    @account_activation = AccountActivation.new
  end

  # GET /account_activations/1/edit
  def edit
  end

	def create
		user = current_user
		user.send_activation_letter
		@user = user
		notice_text = t('Activation letter sent')
		respond_to do |format|
	        format.js { render :json => { :html => notice_text}, :content_type => 'text/json' }
	        format.html { redirect_to @user, notice: notice_text }
	        #format.html { redirect_to @user, notice: t('Activation letter sent.') }
	    end
	end

	def activate
    user = current_user
		@account_activation = @aa = AccountActivation.find_token(params[:token])
		@link_already_activated = @aa.user_id == user.id  && user.activated
		if  @aa && !@link_already_activated
			@not_logged_in = !(logged_in?)
			@wrong_user = user && (@aa.user_id != user.id)
			if user && (@aa.user_id == user.id)
				@email_changed = user && (user.email != @aa.email)
				@user_already_activated= user.activated
				if  user && !@email_changed
					# @aa.update_attribute(:activated, true)
					user.update_attribute(:activated, true)
					@success = true
					#TODO: clean all activation records with same email and other users if exists
				end
			end
		end
  end




  # DELETE /account_activations/1 or /account_activations/1.json
  def destroy
    @account_activation.destroy

    respond_to do |format|
      format.html { redirect_to account_activations_url, notice: "Account activation was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_account_activation
      @account_activation = AccountActivation.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def account_activation_params
      params.require(:account_activation).permit(:user_id, :token, :email)
    end

    #gets user
    def current_user
      if session[:user_id]
        @current_user ||= User.find_by(id: session[:user_id])
      elsif cookies.signed[:remember_token]
        s = Session.find_by(token: cookies.signed[:remember_token])
        if s
          id = s.user_id
          u = User.find_by(id: id)
          if u
            log_in(u)
            return @current_user ||= u
          end
        end
        cookies.delete(:remember_token)
        @current_user = nil
      end
    end

    # Returns true if the user is logged in, false otherwise.
    def logged_in?
      !current_user.nil?
    end
end
