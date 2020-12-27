Rails.application.routes.draw do
	# UsersController
	match '/v1/signup', to: 'users#signup', via: :post
	match '/v1/user', to: 'users#get_user', via: :get
	
	# SessionsController
	match '/v1/session', to: 'sessions#create_session', via: :post
	match '/v1/session', to: 'sessions#delete_session', via: :delete

	# TablesController
	match '/v1/table', to: 'tables#create_table', via: :post
	match '/v1/table/:id', to: 'tables#get_table', via: :get

	# TablesObjectsController
	match '/v1/table_object', to: 'table_objects#create_table_object', via: :post
	match '/v1/table_object/:id', to: 'table_objects#get_table_object', via: :get
	match '/v1/table_object/:id', to: 'table_objects#update_table_object', via: :put
	match '/v1/table_object/:id', to: 'table_objects#delete_table_object', via: :delete
	match '/v1/table_object/:id/file', to: 'table_objects#set_table_object_file', via: :put
	match '/v1/table_object/:id/file', to: 'table_objects#get_table_object_file', via: :get

	# WebsocketConnectionsController
	match '/v1/websocket_connection', to: 'websocket_connections#create_websocket_connection', via: :post

	# Websocket connections
	mount ActionCable.server => '/v1/cable'
end
