Rails.application.routes.draw do
  resources :descriptions
  resources :word_in_sets
  resources :word_sets
  resources :translations
  resources :words
  resources :dialects
  resources :languages

  #welcome
  root 'pseudo_static#welcome'
  get '/:locale' => 'pseudo_static#welcome', as: :pseudo_root

  scope "(:locale)", locale: /en|ru/ do

    get 'sigil' => 'pseudo_static#sigil',  as: :sigil
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

    #activation stuff
    # resources :account_activations
    post 'account_activations' => 'account_activations#create'
    post 'account_activations/:token' => 'account_activations#activate' , as: :account_activate
    get 'account_activations/:token' => 'account_activations#activate' #try to avoid use get

    #pasword reset stuff
    #  resources :password_resets
    get 'reset_request'  => 'password_resets#new' #get reset request form
    post 'send_reset_request'  => 'password_resets#create' #sends password request and creates corresponding record in db
    get 'password_resets/:token' => 'password_resets#edit', as: :password_reset #get password reset form
    patch 'reset_password' => 'password_resets#reset' #finally changes password in user, reset record in db can be deleted


    resources :shultes
    resources :pick_word_in_sets
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html


end
