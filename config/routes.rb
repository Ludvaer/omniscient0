Rails.application.routes.draw do
  root 'pseudo_static#welcome'
  get 'pseudo_static/welcome'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
