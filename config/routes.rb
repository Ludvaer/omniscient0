Rails.application.routes.draw do


  # Defines the root path route ("/")
  # root "articles#index"
  root 'pseudo_static#welcome'
  get 'pseudo_static/welcome', as: :pseudo_root

  #signup view destroy users
  resources :users
  get 'signup'  => 'users#new'

  #login - logout
  resources :sessions
  get    'login'   => 'sessions#new'
  post   'login'   => 'sessions#create'
  get 'logout'  => 'sessions#destroy' #TODO: fix; no logout through get
  delete 'logout'  => 'sessions#destroy'
  get 're session'  => 'sessions#reset' #simulates session reset (reopening browser) (clears session cookie)


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html


end
