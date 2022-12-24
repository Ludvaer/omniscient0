module HasSecurityToken
	extend ActiveSupport::Concern

	def get_token
    	return @token_string + '|' + self.id.to_s           #you can encrypt here
	end
	def init_token
		token = self.class.new_token
		self.token = self.hash_token(token)
		@token_string = token
	end
	def hash_token(token)
		digest = OpenSSL::Digest.new('sha256')
		return OpenSSL::HMAC.digest(digest, user_id.to_s, token).unpack('H*')[0]
	end

	module ClassMethods
		def find_token(token)
			parsed = token.rpartition('|')                      #and decrypt here
			aa = find_by(id: parsed[-1])
			return aa if aa and aa.token == aa.hash_token(parsed[0])
			return nil
		end
		def new_token
			return SecureRandom.urlsafe_base64;
		end
	end


end
