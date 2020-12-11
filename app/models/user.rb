class User < ApplicationRecord
	has_one :dev, dependent: :destroy
	has_many :app_users, dependent: :destroy
	has_many :table_objects, dependent: :destroy
	has_many :sessions, dependent: :destroy
	has_many :table_object_user_access, dependent: :destroy

	has_secure_password
end