Rails.application.routes.draw do
	# UsersController
	match '/v1/signup', to: 'users#signup', via: :post
	match '/v1/users', to: 'users#get_users', via: :get
	match '/v1/user', to: 'users#get_user', via: :get
	match '/v1/user', to: 'users#update_user', via: :put
	match '/v1/user/profile_image', to: 'users#set_profile_image_of_user', via: :put
	match '/v1/user/profile_image', to: 'users#get_profile_image_of_user', via: :get
	match '/v1/user/:id/profile_image', to: 'users#get_profile_image_of_user_by_id', via: :get
	match '/v1/user/stripe', to: 'users#create_stripe_customer_for_user', via: :post
	match '/v1/user/:id', to: 'users#get_user_by_id', via: :get
	match '/v1/user/:id/send_confirmation_email', to: 'users#send_confirmation_email', via: :post
	match '/v1/user/send_password_reset_email', to: 'users#send_password_reset_email', via: :post
	match '/v1/user/:id/confirm', to: 'users#confirm_user', via: :post
	match '/v1/user/:id/save_new_email', to: 'users#save_new_email', via: :post
	match '/v1/user/:id/save_new_password', to: 'users#save_new_password', via: :post
	match '/v1/user/:id/reset_email', to: 'users#reset_email', via: :post
	match '/v1/user/:id/password', to: 'users#set_password', via: :put

	# DevsController
	match '/v1/dev', to: 'devs#get_dev', via: :get

	# ProvidersController
	match '/v1/provider', to: 'providers#create_provider', via: :post
	match '/v1/provider', to: 'providers#get_provider', via: :get

	# SessionsController
	match '/v1/session', to: 'sessions#create_session', via: :post
	match '/v1/session/access_token', to: 'sessions#create_session_from_access_token', via: :post
	match '/v1/session/renew', to: 'sessions#renew_session', via: :put
	match '/v1/session', to: 'sessions#delete_session', via: :delete

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
	match '/v1/table_object/:uuid', to: 'table_objects#get_table_object', via: :get
	match '/v1/table_object/:uuid', to: 'table_objects#update_table_object', via: :put
	match '/v1/table_object/:uuid', to: 'table_objects#delete_table_object', via: :delete
	match '/v1/table_object/:uuid/file', to: 'table_objects#set_table_object_file', via: :put
	match '/v1/table_object/:uuid/file', to: 'table_objects#get_table_object_file', via: :get
	match '/v1/table_object/:uuid/access', to: 'table_objects#add_table_object', via: :post
	match '/v1/table_object/:uuid/access', to: 'table_objects#remove_table_object', via: :delete

	# PurchasesController
	match '/v1/purchase', to: 'purchases#create_purchase', via: :post
	match '/v1/purchase/:uuid', to: 'purchases#get_purchase', via: :get
	match '/v1/purchase/:uuid/complete', to: 'purchases#complete_purchase', via: :post
	match '/v1/purchase/:uuid', to: 'purchases#delete_purchase', via: :delete

	# PurchasesController v2
	match '/v2/table_objects/:uuid/purchases', to: 'purchases#list_purchases_of_table_object', via: :get

	# CollectionsController
	match '/v1/collection/table_objects', to: 'collections#set_table_objects_of_collection', via: :put

	# CollectionsController v2
	match '/v2/collections/:name/table_objects/:uuid', to: 'collections#add_table_object_to_collection', via: :post

	# WebPushSubscriptionsController
	match '/v1/web_push_subscription', to: 'web_push_subscriptions#create_web_push_subscription', via: :post
	match '/v1/web_push_subscription/:uuid', to: 'web_push_subscriptions#get_web_push_subscription', via: :get
	match '/v1/web_push_subscription/:uuid', to: 'web_push_subscriptions#delete_web_push_subscription', via: :delete

	# NotificationsController
	match '/v1/notification', to: 'notifications#create_notification', via: :post
	match '/v1/notifications', to: 'notifications#get_notifications', via: :get
	match '/v1/notification/:uuid', to: 'notifications#update_notification', via: :put
	match '/v1/notification/:uuid', to: 'notifications#delete_notification', via: :delete

	# ApisController
	match '/v1/api/:id/call/*path', to: 'apis#api_call', via: [:post, :get, :put, :delete]
	match '/v1/api/:id/:slot/call/*path', to: 'apis#api_call', via: [:post, :get, :put, :delete]
	match '/v1/api', to: 'apis#create_api', via: :post
	match '/v1/api/:id/:slot/compile', to: 'apis#compile_api', via: :put

	# ApiEndpointsController
	match '/v1/api/:id/:slot/endpoint', to: 'api_endpoints#set_api_endpoint', via: :put

	# ApiFunctionsController
	match '/v1/api/:id/:slot/function', to: 'api_functions#set_api_function', via: :put

	# ApiErrorsController
	match '/v1/api/:id/:slot/errors', to: 'api_errors#set_api_errors', via: :put

	# ApiEnvVarsController
	match '/v1/api/:id/:slot/env_vars', to: 'api_env_vars#set_api_env_vars', via: :put

	# WebsocketConnectionsController
	match '/v1/websocket_connection', to: 'websocket_connections#create_websocket_connection', via: :post

	# AppUsersController
	match '/v1/app/:id/users', to: 'app_users#get_app_users', via: :get

	# UserSnapshotsController
	match '/v1/user_snapshots', to: 'user_snapshots#get_user_snapshots', via: :get

	# AppUserSnapshotsController
	match '/v1/app/:id/user_snapshots', to: 'app_user_snapshots#get_app_user_snapshots', via: :get

	# CheckoutSessionsController
	match '/v1/checkout_session', to: 'checkout_sessions#create_checkout_session', via: :post

	# CustomerPortalSessionsController
	match '/v1/customer_portal_session', to: 'customer_portal_sessions#create_customer_portal_session', via: :post

	# TasksController
	match '/v1/tasks/create_user_snapshots', to: 'tasks#create_user_snapshots', via: :put
	match '/v1/tasks/send_notifications', to: 'tasks#send_notifications', via: :put
	match '/v1/tasks/delete_sessions', to: 'tasks#delete_sessions', via: :put
	match '/v1/tasks/delete_purchases', to: 'tasks#delete_purchases', via: :put
	match '/v1/tasks/update_redis_caches', to: 'tasks#update_redis_caches', via: :put

	# Stripe Webhooks
	mount StripeEvent::Engine, at: '/v1/stripe'

	# Websocket connections
	mount ActionCable.server => '/v1/cable'
end
