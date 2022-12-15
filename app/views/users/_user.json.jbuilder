json.extract! user, :id, :name, :email, :password_digest, :token, :downame, :activated, :created_at, :updated_at
json.url user_url(user, format: :json)
