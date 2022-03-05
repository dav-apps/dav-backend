class User < ApplicationRecord
	has_one :dev, dependent: :destroy
	has_one :provider, dependent: :destroy
	has_one :user_profile_image, dependent: :destroy
	has_many :app_users, dependent: :destroy
	has_many :apps, through: :app_users
	has_many :table_etags, dependent: :destroy
	has_many :table_objects, dependent: :destroy
	has_many :sessions, dependent: :destroy
	has_many :table_object_user_access, dependent: :destroy
	has_many :purchases, dependent: :destroy
	has_many :notifications, dependent: :destroy
	has_many :websocket_connections, dependent: :destroy
	has_many :api_endpoint_request_cache_dependencies

	has_secure_password
end