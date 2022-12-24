json.extract! account_activation, :id, :user_id, :token, :email, :created_at, :updated_at
json.url account_activation_url(account_activation, format: :json)
