Rails.application.routes.draw do
	# UsersController
	match '/v1/signup', to: 'users#signup', via: :post
	
	# SessionsController
	match '/v1/session', to: 'sessions#create_session', via: :post
	match '/v1/session', to: 'sessions#delete_session', via: :delete

	# TablesController
	match '/v1/table', to: 'tables#create_table', via: :post
	match '/v1/table/:id', to: 'tables#get_table', via: :get
end
