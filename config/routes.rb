Rails.application.routes.draw do
	# UsersController
	match '/v1/signup', to: 'users#signup', via: :post
	match '/v1/users', to: 'users#get_users', via: :get
	match '/v1/user', to: 'users#get_user', via: :get
	match '/v1/user', to: 'users#update_user', via: :put
	match '/v1/user/:id/confirm', to: 'users#confirm_user', via: :post
	match '/v1/user/:id/save_new_email', to: 'users#save_new_email', via: :post
	match '/v1/user/:id/save_new_password', to: 'users#save_new_password', via: :post
	match '/v1/user/:id/reset_email', to: 'users#reset_email', via: :post
	
	# SessionsController
	match '/v1/session', to: 'sessions#create_session', via: :post
	match '/v1/session/jwt', to: 'sessions#create_session_from_jwt', via: :post
	match '/v1/session', to: 'sessions#delete_session', via: :delete

	# DevsController
	match '/v1/dev', to: 'devs#get_dev', via: :get

	# AppsController
	match '/v1/app', to: 'apps#create_app', via: :post
	match '/v1/apps', to: 'apps#get_apps', via: :get
	match '/v1/app/:id', to: 'apps#get_app', via: :get
	match '/v1/app/:id', to: 'apps#update_app', via: :put

	# TablesController
	match '/v1/table', to: 'tables#create_table', via: :post
	match '/v1/table/:id', to: 'tables#get_table', via: :get

	# TableObjectsController
	match '/v1/table_object', to: 'table_objects#create_table_object', via: :post
	match '/v1/table_object/:id', to: 'table_objects#get_table_object', via: :get
	match '/v1/table_object/:id', to: 'table_objects#update_table_object', via: :put
	match '/v1/table_object/:id', to: 'table_objects#delete_table_object', via: :delete
	match '/v1/table_object/:id/file', to: 'table_objects#set_table_object_file', via: :put
	match '/v1/table_object/:id/file', to: 'table_objects#get_table_object_file', via: :get
	match '/v1/table_object/:id/access', to: 'table_objects#add_table_object', via: :post
	match '/v1/table_object/:id/access', to: 'table_objects#remove_table_object', via: :delete

	# WebPushSubscriptionsController
	match '/v1/web_push_subscription', to: 'web_push_subscriptions#create_web_push_subscription', via: :post

	# NotificationsController
	match '/v1/notification', to: 'notifications#create_notification', via: :post
	match '/v1/notifications', to: 'notifications#get_notifications', via: :get
	match '/v1/notification/:uuid', to: 'notifications#update_notification', via: :put
	match '/v1/notification/:uuid', to: 'notifications#delete_notification', via: :delete

	# UserActivitiesController
	match '/v1/user_activities', to: 'user_activities#get_user_activities', via: :get

	# AppUserActivitiesController
	match '/v1/app/:id/user_activities', to: 'app_user_activities#get_app_user_activities', via: :get

	# AppUsersController
	match '/v1/app/:id/users', to: 'app_users#get_app_users', via: :get

	# ApisController
	match '/v1/api/:id/call/*path', to: 'apis#api_call', via: [:post, :get, :put, :delete]
	match '/v1/api', to: 'apis#create_api', via: :post
	match '/v1/api/:id', to: 'apis#get_api', via: :get

	# ApiEndpointsController
	match '/v1/api/:id/endpoint', to: 'api_endpoints#set_api_endpoint', via: :put

	# ApiFunctionsController
	match '/v1/api/:id/function', to: 'api_functions#set_api_function', via: :put

	# ApiErrorsController
	match '/v1/api/:id/errors', to: 'api_errors#set_api_errors', via: :put

	# ApiEnvVarsController
	match '/v1/api/:id/env_vars', to: 'api_env_vars#set_api_env_vars', via: :put

	# WebsocketConnectionsController
	match '/v1/websocket_connection', to: 'websocket_connections#create_websocket_connection', via: :post

	# Websocket connections
	mount ActionCable.server => '/v1/cable'
end
