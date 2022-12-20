class Session < ActiveRecord::Base
	validates :user_id,  presence: true
	validates :token,  presence: true, uniqueness: { case_sensitive: true }
	def init_token
		self.token = SecureRandom.urlsafe_base64;
	end

  def index
    @sessions = Session.all
  end

end
