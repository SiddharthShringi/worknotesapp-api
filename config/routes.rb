Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }, defaults: { format: :json }
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  namespace :api do
    namespace :v1 do
      resources :projects, only: [ :index, :create, :update, :destroy ]
      resources :work_sessions, only: [ :index, :create, :update, :destroy ] do
        member do
          patch :stop
        end
        collection do
          get :active
        end
      end
    end
  end
end
