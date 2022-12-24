json.extract! password_reset, :id, :user_id, :token, :created_at, :updated_at
json.url password_reset_url(password_reset, format: :json)
