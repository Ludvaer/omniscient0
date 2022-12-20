module SessionsHelper
	# Logs in the given user.
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

	# Returns the current logged-in user (if any).
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

	#determines if logged in user has right to modify data related to argument user
	def access?(user)
		current_user and (current_user.id == user.id or current_user.id == 1)
	end

	def redirect_link(redirect_url)
		@redirect_url = redirect_url
	   render_to_string 'sessions/_redirect_link', redirect_url: redirect_url
	end

end
