Rails.application.routes.draw do
	# UsersController
	match '/v1/signup', via: :post, to: 'users#signup'
	
	# SessionsController
	match '/v1/session', via: :post, to: 'sessions#create_session'
	match '/v1/session', via: :delete, to: 'sessions#delete_session'
end
