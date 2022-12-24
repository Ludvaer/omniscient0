require 'openssl'
MAX_USERNAME_LENGTH = 50
MIN_USERNAME_LENGTH = 2
MAX_EMAIL_LENGTH = 255
#MIN_EMAIL_LENGTH is not definrd cause i don't realy whant to know and it's anyway checked through regular expressions
VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
VALID_USER_REGEX = /\A[\w+\-@. ]+\z/i
PASSWORD_LENGTH = 64
class User < ActiveRecord::Base
#TODO: check that password magic works when username changed
	validates :name,  presence: true, length: { maximum: MAX_USERNAME_LENGTH,  minimum: MIN_USERNAME_LENGTH},
		format: { with: VALID_USER_REGEX }#, uniqueness: { case_sensitive: false }
		               #uniqueness checked during validation, removed here to avoid ext db queries
	validates :email, presence: true, length: { maximum: MAX_EMAIL_LENGTH },
		format: { with: VALID_EMAIL_REGEX }#, uniqueness: { case_sensitive: false }
	validates :password, presence: true, length: { minimum: PASSWORD_LENGTH, maximum: PASSWORD_LENGTH}
	validates :downame,  presence: true, length: { maximum: MAX_USERNAME_LENGTH,  minimum: MIN_USERNAME_LENGTH},
		format: { with: VALID_USER_REGEX }
	has_secure_password

	def create_activation
		aa = AccountActivation.new
		aa.email = email
		aa.user_id = id
		aa.init_token
		aa.save
		@activation = aa
	end

	def account_activation
		create_activation unless @activation
		return @activation
	end

	def send_activation_letter
		UserMailer.account_activation(account_activation).deliver
	end

	#TODO: look above, look below, DRY!?

	def create_password_reset
		pr = PasswordReset.new
		pr.user_id = id
		pr.init_token
		pr.save
		@password_reset = pr
	end

	def password_reset
		create_password_reset unless @password_reset
		return @password_reset
	end

	def send_password_reset_letter
		UserMailer.password_reset(self).deliver
	end


    #will need to refactor and probably rebuild some of encription and other stuff some of it should be placed in helpers
	@@sym = [('0'..'9'), ('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
    @@rsa_key = OpenSSL::PKey::RSA.new(2048)
    @@ssl = "asdfasdfasdfasdf"
    @@salts = Hash.new(false)
    @@users = Hash.new(nil)
    @@usersbymail = Hash.new(nil)
    @@i = 1

	def self.key
		@@rsa_key.public_key
	end

	def self.decrypt(password)
		@@rsa_key.private_decrypt([password].pack('H*'))
	end

	def has_pass?
		if password and password.length == PASSWORD_LENGTH
			return password != hash_pass('')
		end
		return false
	end

	def hash_pass(pass)
		digest = OpenSSL::Digest.new('sha256')
		return OpenSSL::HMAC.digest(digest, name.downcase, pass).unpack('H*')[0]
	end

	def self.salt
		l = @@sym.length
		salt = (0...5).map { @@sym[rand(l)] }.join + "#{@@i}"
		@@i += 1
		Rails.cache.fetch salt do
			true
		end
    Rails.cache.write(salt, true,expires_in: 1.hour)
    p "salt generated #{salt}"
    p "value cached for #{salt} key #{Rails.cache.read(salt)}"
		return salt
	end

	def self.log_in(remember = false)
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

	def self.checksalt(salt)
    p "value cached for #{salt} key #{Rails.cache.read(salt)}"
		if Rails.cache.fetch(salt)
			Rails.cache.fetch salt do
				false
			end
      p "salt checked #{salt} true"
			return true
		else
      p "salt checked #{salt} false"
			return false
		end
	end


	def has_name?()
		return !name.blank?
	end

	def long_enough_name?()
		return name.length >= MIN_USERNAME_LENGTH
	end

	def valid_name?()
		return VALID_USER_REGEX.match(name)
	end

	def short_enough_name?()
		return name.length <= MAX_USERNAME_LENGTH
	end

	def short_enough_email?()
		return email.length <= MAX_EMAIL_LENGTH
	end

	def has_email?()
		return !email.blank?
	end

	def valid_email?()
		return VALID_EMAIL_REGEX.match(email)
	end


	def check_unique(users)
		if id
			return ((users.length == 0) or ((users.length == 1) and (id == users[0].id)))
		else
			return (users.length == 0)
		end
	end

	def unique_name?
		#return @@users[self.name.downcase].nil?
		check_unique User.where(downame: downame)
	end

	def unique_email?
		#return @@usersbymail[self.email.downcase].nil?
		check_unique User.where(email: email)
	end

# class NameErrors
	attr_accessor  :name_empty, :name_too_short, :name_too_long, :name_invalid, :name_unknown, :name_taken;
# PasswordErrors
	attr_accessor  :password_empty, :password_invalid, :password_decryption_failed, :password_doublepost;
# Old Password Errors
	attr_accessor  :old_password_empty, :old_password_invalid, :password_ignored;
# ConfirmationErrors
	attr_accessor  :password_confirmation_empty, :password_confirmation_not_match, :password_confirmation_decryption_failed, :password_confirmation_doublepost;
# MailErrors
	attr_accessor  :email_empty, :email_too_long, :email_invalid, :email_taken, :email_unknown;
#dlobal errors
    attr_accessor  :err, :decryption_failed, :doublepost;


	def check_name (user_params)
		self.name = user_params[:name].squish()
		self.downame = name.downcase
		unless @name_empty = !has_name?
	    	@name_too_short = !long_enough_name?
	    	@name_too_long = !short_enough_name?
	    	unless @name_too_short or @name_too_long
		    	unless @name_invalid = !valid_name?
		          	return true
		        end
	        end
		end
		@err ||= true;
		return false
	end

	def check_name_unique
		@err ||= (@name_taken = !unique_name?)
        return !@name_taken
	end
	def check_email_unique
		@err ||= (@email_taken = !unique_email?)
        return !@email_taken
	end

	def decrypt(password,encrypted, salt)
		if  encrypted
			begin
		  	  	d1 = User.decrypt(encrypted)
		  	  	decrypted = d1.rpartition('|')
		  	  	decryption_failed = false
			rescue
				decrypted = ['','|','']
				decryption_failed = true
			end
		else
		  decrypted = [hash_pass(password),'|', salt]
		  decryption_failed = false
		end
		return decrypted,decryption_failed
	end

	def check_old_password (user_params)
		decrypted, @decryption_failed  = decrypt(user_params[:old_password],user_params[:old_password_encrypted],user_params[:salt])
		#@doublepost ||=  !User.checksalt(decrypted[-1]) unless decryption_failed
    p "doublepost:#{doublepost}"
		@old_password = decrypted[0]
		@old_password_empty = (decrypted[0] == hash_pass(''))
		@err ||= (@decryption_failed || @doublepost || @old_password_empty)
	end

	def check_password (user_params)
		decrypted, decryption_failed = decrypt(user_params[:password],user_params[:password_encrypted],user_params[:salt])
		@decryption_failed ||= decryption_failed
	  #	@doublepost ||=  !User.checksalt(decrypted[-1]) unless decryption_failed
		self.password = decrypted[0]
		@password_empty = (decrypted[0] == hash_pass(''))
		@err ||= (decryption_failed || doublepost || @password_empty)
	end

	def check_password_confirmation (user_params)
		decrypted, decryption_failed = decrypt(user_params[:password_confirmation],user_params[:password_confirmation_encrypted],user_params[:salt])
		@decryption_failed ||= decryption_failed
		# @doublepost ||=  !User.checksalt(decrypted[-1]) unless decryption_failed
		@password_confirmation_empty = (decrypted[0] == hash_pass(''))
		#unless @password_confirmation_empty = (decrypted[0] == User.hash_pass(''))
			@password_confirmation_not_match = password != decrypted[0]
		#end
		@err ||= decryption_failed || doublepost || @password_confirmation_empty || @password_confirmation_not_match
	end

	def check_email (user_params)
		self.email = user_params[:email].squish().downcase
		unless @email_empty = !has_email?
	  		unless @email_too_long = !short_enough_email?
			  	unless @email_invalid = !valid_email?
			  	  	@email_taken = !unique_email?
			  	  	@email_unknown = !@email_taken
			  	end
	  	  	end
	  	end
	  	@err ||= (@email_empty || @email_too_long ||  @email_invalid || @email_taken)
	end


	def validate_signup_input(user_params)
		@err = false
	    if(check_name(user_params))
	    	check_name_unique
	    end
	    check_password(user_params)
	    check_password_confirmation(user_params)
	    if check_email(user_params)
		    check_email_unique
	    end

	    # "signup pass #{password}"
		return !@err
	end

	def validate_edit_input(user_params)
	    @err = false

		check_old_password(user_params)

		if ((!@err) and (!authenticate(@old_password)))
			@old_password_invalid = true
			@err = true
		end

		if(check_name(user_params))
	    	check_name_unique
		end

		err_backup = @err
        check_password(user_params)
	    check_password_confirmation(user_params)
	    # "old pass #{@old_password}"
	    # "edited pass #{password}"
	    if (@password_confirmation_empty && @password_empty)
	    	# "edited pass ignored"
	    	@err = err_backup;
	    	@password_confirmation_empty = false
	    	@password_empty = false
	    	@password_ignored = true
	    	self.password_confirmation = @old_password
	    	self.password =  @old_password
	    end

	    if check_email(user_params)
		    check_email_unique
	    end

		return !@err
	end

	def validate_login_input(user_params)
		@err = false
	    user = self
	    check_name(user_params)
   		check_password(user_params)

		unless @err
			user = User.find_by(downame: name.downcase)
	        if user
	        	# "input pass #{password}"
		        if user.authenticate(password)
		        	return user
		        else
		        	@password_invalid = true
		        end
	        else
	        	@name_unknown = true
	        end
		end
		@err = true;
		return self
	end

	def validate_email_input(user_params)
		@err = false
		user = self
		if check_email(user_params)
			user = User.find_by(email: email)
			if user
				return user
			end
		end
		return self
	end

	def validate_password_input(user_params)
		@err = false
		check_password(user_params)
	    check_password_confirmation(user_params)
	    return !@err
	end


end
