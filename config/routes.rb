Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  resource :session, only: [ :create ]

  resources :username_seats, only: [ :show ], param: :username,
             path: "username-seats"

  resources :users, only: [ :create, :show, :update ], param: :username

  resources :posts, only: [ :index, :create, :destroy ]

  resources :user_relationships, only: [ :create, :show ],
            path: "user-relationships"
end
