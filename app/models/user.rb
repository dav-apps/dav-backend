class User < ApplicationRecord
	has_one :dev, dependent: :destroy
	has_many :table_objects, dependent: :destroy

	has_secure_password
end