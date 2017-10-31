Rails.application.routes.draw do
  root 'teams#index'

  get 'projections/index'

  get 'players/index'

  get 'teams/show'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
