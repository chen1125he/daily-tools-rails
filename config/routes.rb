# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  namespace :api do
    namespace :v1 do
      defaults format: 'json' do
        post 'auth/sign_in', to: 'auth#sign_in'
        post 'auth/refresh', to: 'auth#refresh'
        get 'auth/me', to: 'auth#me'
        delete 'auth/sign_out', to: 'auth#sign_out'
        patch 'auth/password', to: 'auth#password'
        resources :users, only: %i[index]
        resources :chores, only: %i[index show create update]
        resources :chore_records, only: %i[index show create update destroy] do
          post 'parse_from_text', on: :collection
        end
        resources :ingredients, only: %i[index show create update destroy]
        resources :recipes, only: %i[index show create update destroy] do
          post 'parse_from_text', on: :collection
        end
        resources :menus, only: %i[index show create update destroy] do
          post 'generate', on: :collection
        end
      end
    end
  end
end
