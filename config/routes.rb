Rails.application.routes.draw do

  # Defines the root path route ("/")
  # root "articles#index"
  root 'pseudo_static#welcome'
  get 'pseudo_static/welcome'

  #signup view destroy users
  resources :users
  get 'signup'  => 'users#new'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html


end
