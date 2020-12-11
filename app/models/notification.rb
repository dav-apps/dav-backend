class Notification < ApplicationRecord
	belongs_to :user
	belongs_to :app
	has_many :notification_properties, dependent: :destroy
end