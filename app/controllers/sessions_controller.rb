class SessionsController < ApplicationController
    before_action :init_form

	def new
	end

  def index
    @sessions = Session.all
  end
	def reset
		reset_session
		respond_to do |format|
			flash[:notice] = t('Session reseted.')
		    format.html { redirect_to root_path }
		end
	end

   	def create
		@user = @user.validate_login_input(user_params)
		err = @user.err
		@is_login = true

	    unless err
	      flash[:notice] = t('Login successful.')
	      redirect_url = params[:redirect_url]
	      redirect_url ||= users_url(id: @user)
        log_in(@user,login_params[:remember] == "1")
	      respond_to do |format|
	        format.js {	render :json => { :html => redirect_link(redirect_url), redirect: true}, :content_type => 'text/json'}
	        format.html { redirect_to redirect_url }
	      end
	    else
	      respond_to do |format|
	        format.js { render :json => { :html => render_to_string('users/_form'), redirect: false}, :content_type => 'text/json' }
	        format.html { render :new }
	      end
	    end
	end

	def destroy
		log_out()
		respond_to do |format|
			flash[:notice] = t('Logout successfull.')
		    format.html { redirect_to root_path }
		end
	end

	private
		def login_params
			params.require(:login).permit(:remember)
		end
	    def user_params
			params.require(:user).permit(:name, :password, :password_encrypted, :salt)
	    end
		def init_form
			@user = User.new
			@islogin = true
			@publickey = User.key
			@salt = User.salt
		end
    # Logs in the current user.
    def log_in(user, remember = false)
  		id = user.id
  		if remember
  			s = Session.new
  			s.init_token
  			s.user_id = id
  			if s.save
  				cookies.signed.permanent[:remember_token] = s.token
  			end
  		end
  		session[:user_id] = id
  	end
    def redirect_link(redirect_url)
  		@redirect_url = redirect_url
  	   render_to_string 'sessions/_redirect_link', redirect_url: redirect_url
  	end
    # Logs out the current user.
    def log_out
      if cookies.signed[:remember_token]
        s = Session.find_by(token: cookies.signed[:remember_token])
        if s
          cookies.delete(:remember_token)
          s.destroy
        end
      end
      session.delete(:user_id)
      @current_user = nil
    end
end
